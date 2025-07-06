import Foundation
import Logging

@MainActor
class BackupService: ObservableObject {
    private let logger = Logger(label: "BackupService")
    private let imapService = IMAPService()
    private let fileManager = FileManager.default
    
    @Published var isRunning = false
    private var currentTask: Task<Void, Never>?
    
    func startBackup(
        accounts: [Account],
        backupDirectory: URL,
        progress: BackupProgress
    ) async {
        guard !isRunning else {
            logger.warning("Backup already running")
            return
        }
        
        isRunning = true
        logger.info("Starting backup for \(accounts.count) accounts")
        
        currentTask = Task {
            await progress.startBackup(accounts: accounts)
            
            do {
                try await performBackup(accounts: accounts, backupDirectory: backupDirectory, progress: progress)
                logger.info("Backup completed successfully")
                await progress.completeBackup()
            } catch {
                logger.error("Backup failed: \(error)")
                await progress.updateAccountProgress(
                    accountName: progress.currentAccount,
                    error: error.localizedDescription
                )
            }
            
            await MainActor.run {
                isRunning = false
            }
        }
    }
    
    func cancelBackup() {
        currentTask?.cancel()
        currentTask = nil
        isRunning = false
    }
    
    nonisolated private func performBackup(
        accounts: [Account],
        backupDirectory: URL,
        progress: BackupProgress
    ) async throws {
        
        for account in accounts {
            guard !Task.isCancelled else {
                await progress.cancelBackup()
                return
            }
            
            logger.info("Starting backup for account: \(account.name)")
            
            do {
                try await backupAccount(account, backupDirectory: backupDirectory, progress: progress)
                await progress.updateAccountProgress(accountName: account.name, isComplete: true)
                logger.info("Successfully completed backup for account: \(account.name)")
            } catch {
                logger.error("Failed to backup account \(account.name): \(error)")
                await progress.updateAccountProgress(
                    accountName: account.name,
                    error: "Failed to backup: \(error.localizedDescription)"
                )
                // Don't throw error, continue with other accounts
                continue
            }
        }
    }
    
    nonisolated private func backupAccount(
        _ account: Account,
        backupDirectory: URL,
        progress: BackupProgress
    ) async throws {
        
        // Create account directory
        let accountDir = backupDirectory.appendingPathComponent(account.name)
        try FileManager.default.createDirectory(at: accountDir, withIntermediateDirectories: true)
        
        // Connect to IMAP server
        let imapService = IMAPService()
        let connection = try await imapService.connect(to: account)
        defer {
            Task {
                await connection.disconnect()
            }
        }
        
        // Get folder list
        let folders = try await connection.listFolders()
        await progress.updateAccountProgress(
            accountName: account.name,
            totalFolders: folders.count
        )
        
        var completedFolders = 0
        var totalNewEmails = 0
        
        for folder in folders {
            guard !Task.isCancelled else {
                await progress.cancelBackup()
                return
            }
            
            logger.info("Processing folder: \(folder.name)")
            await progress.updateAccountProgress(
                accountName: account.name,
                currentFolder: folder.name
            )
            
            // Add a small delay to make progress visible
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            let newEmails = try await backupFolder(
                folder,
                connection: connection,
                accountDir: accountDir,
                progress: progress
            )
            
            totalNewEmails += newEmails
            completedFolders += 1
            
            await progress.updateAccountProgress(
                accountName: account.name,
                completedFolders: completedFolders,
                newEmails: totalNewEmails
            )
            
            logger.info("Completed folder \(folder.name): \(newEmails) new emails")
        }
        
        logger.info("Completed backup for account: \(account.name), new emails: \(totalNewEmails)")
    }
    
    nonisolated private func backupFolder(
        _ folder: IMAPFolder,
        connection: IMAPConnection,
        accountDir: URL,
        progress: BackupProgress
    ) async throws -> Int {
        
        let folderDir = accountDir.appendingPathComponent(folder.name)
        try FileManager.default.createDirectory(at: folderDir, withIntermediateDirectories: true)
        
        // Get existing message UIDs to avoid duplicates
        let existingUIDs = getExistingMessageUIDs(in: folderDir)
        
        // Fetch new messages
        let messages = try await connection.getMessages(in: folder.name, excludingUIDs: existingUIDs)
        
        for message in messages {
            guard !Task.isCancelled else {
                return 0
            }
            
            try await saveMessage(message, to: folderDir)
        }
        
        return messages.count
    }
    
    nonisolated private func getExistingMessageUIDs(in folderDir: URL) -> Set<UInt32> {
        guard let contents = try? FileManager.default.contentsOfDirectory(at: folderDir, includingPropertiesForKeys: nil) else {
            return []
        }
        
        var uids: Set<UInt32> = []
        for file in contents {
            if file.pathExtension == "json" {
                // Read the JSON metadata to get the UID
                if let data = try? Data(contentsOf: file),
                   let metadata = try? JSONDecoder().decode(MessageMetadata.self, from: data) {
                    uids.insert(metadata.uid)
                }
            }
        }
        
        return uids
    }
    
    nonisolated private func saveMessage(_ message: IMAPMessage, to folderDir: URL) async throws {
        // Generate filename using sender_date format like Go implementation
        let senderName = message.from.extractSenderName()
        let dateString = message.date.formattedFilename()
        let baseFilename = "\(senderName)_\(dateString)"
        
        let messageFile = folderDir.appendingPathComponent("\(baseFilename).eml")
        let metadataFile = folderDir.appendingPathComponent("\(baseFilename).json")
        
        // Save raw message
        try message.body.write(to: messageFile)
        
        // Create attachments directory if message has attachments
        var attachmentFilenames: [String] = []
        if !message.attachments.isEmpty {
            let attachmentsDir = folderDir.appendingPathComponent("attachments").appendingPathComponent(baseFilename)
            try FileManager.default.createDirectory(at: attachmentsDir, withIntermediateDirectories: true)
            
            for (index, attachment) in message.attachments.enumerated() {
                let sanitizedName = attachment.filename.sanitizedForFilename()
                let attachmentFile = attachmentsDir.appendingPathComponent(sanitizedName)
                
                // Handle duplicate filenames by appending index
                var finalAttachmentFile = attachmentFile
                if FileManager.default.fileExists(atPath: attachmentFile.path) {
                    let fileExtension = attachmentFile.pathExtension
                    let nameWithoutExtension = attachmentFile.deletingPathExtension().lastPathComponent
                    finalAttachmentFile = attachmentsDir.appendingPathComponent("\(nameWithoutExtension)_\(index).\(fileExtension)")
                }
                
                try attachment.data.write(to: finalAttachmentFile)
                attachmentFilenames.append(finalAttachmentFile.lastPathComponent)
            }
        }
        
        // Save metadata with attachment info
        let metadata = MessageMetadata(
            uid: message.uid,
            flags: message.flags,
            subject: message.subject,
            from: message.from,
            to: message.to,
            date: message.date,
            size: message.size,
            headers: message.headers,
            attachments: attachmentFilenames
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let metadataData = try encoder.encode(metadata)
        try metadataData.write(to: metadataFile)
    }
}

private struct MessageMetadata: Codable {
    let uid: UInt32
    let flags: [String]
    let subject: String
    let from: String
    let to: String
    let date: Date
    let size: Int
    let headers: [String: String]
    let attachments: [String]
}
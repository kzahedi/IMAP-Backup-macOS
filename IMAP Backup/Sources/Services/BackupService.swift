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
        logger.info("=== STARTING BACKUP ===")
        logger.info("Backing up \(accounts.count) accounts to: \(backupDirectory.path)")
        for account in accounts {
            logger.info("- Account: \(account.name) (\(account.username))")
        }
        
        currentTask = Task {
            do {
                await progress.startBackup(accounts: accounts)
                
                try await performBackup(accounts: accounts, backupDirectory: backupDirectory, progress: progress)
                logger.info("\n🎉 === BACKUP COMPLETED SUCCESSFULLY ===")
                await progress.completeBackup()
            } catch {
                logger.error("💥 BACKUP FAILED: \(error)")
                logger.error("Error details: \(error.localizedDescription)")
                
                await progress.updateAccountProgress(
                    accountName: progress.currentAccount.isEmpty ? "Unknown" : progress.currentAccount,
                    error: "Backup failed: \(error.localizedDescription)"
                )
                
                // Don't crash the app, just log and complete
                await progress.completeBackup()
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
            
            logger.info("\n=== PROCESSING ACCOUNT: \(account.name) ===")
            logger.info("Account details: \(account.username) @ \(account.host):\(account.port)")
            
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
        logger.info("Found \(folders.count) folders for account \(account.name): \(folders.map { $0.name }.joined(separator: ", "))")
        
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
            
            logger.info("\n--- Processing folder: \(folder.name) ---")
            await progress.updateAccountProgress(
                accountName: account.name,
                currentFolder: folder.name
            )
            
            // Add a small delay to make progress visible
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            
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
            
            logger.info("✓ Completed folder \(folder.name): \(newEmails) new emails (Total so far: \(totalNewEmails))")
        }
        
        logger.info("🎉 COMPLETED BACKUP for account: \(account.name)")
        logger.info("   → Total new emails: \(totalNewEmails)")
        logger.info("   → Folders processed: \(completedFolders)/\(folders.count)")
        logger.info("   → Saved to: \(accountDir.path)")
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
        logger.info("Found \(existingUIDs.count) existing messages in \(folder.name)")
        
        // Fetch new messages
        let messages = try await connection.getMessages(in: folder.name, excludingUIDs: existingUIDs)
        logger.info("Retrieved \(messages.count) new messages from \(folder.name)")
        
        var savedCount = 0
        for (index, message) in messages.enumerated() {
            guard !Task.isCancelled else {
                logger.info("Backup cancelled, saved \(savedCount)/\(messages.count) messages")
                return savedCount
            }
            
            logger.info("Saving message \(index + 1)/\(messages.count): \(message.subject)")
            try await saveMessage(message, to: folderDir)
            savedCount += 1
            
            // Small delay between messages to make progress visible
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 second
        }
        
        logger.info("Successfully saved \(savedCount) messages to \(folderDir.lastPathComponent)")
        return savedCount
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
        do {
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
                    do {
                        let sanitizedName = attachment.filename.sanitizedForFilename()
                        if sanitizedName.isEmpty {
                            continue // Skip invalid filenames
                        }
                        
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
                    } catch {
                        print("Failed to save attachment \(attachment.filename): \(error)")
                        // Continue with other attachments
                    }
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
            
        } catch {
            print("Failed to save message \(message.subject): \(error)")
            throw error
        }
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
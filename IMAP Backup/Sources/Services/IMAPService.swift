import Foundation
import NIO
@preconcurrency import NIOSSL
import Logging

struct IMAPAttachment {
    let filename: String
    let mimeType: String
    let data: Data
    let size: Int
}

struct IMAPMessage {
    let uid: UInt32
    let flags: [String]
    let subject: String
    let from: String
    let to: String
    let date: Date
    let size: Int
    let body: Data
    let headers: [String: String]
    let attachments: [IMAPAttachment]
}

struct IMAPFolder {
    let name: String
    let delimiter: String
    let attributes: [String]
    let messageCount: Int
    let unseenCount: Int
}

class IMAPService {
    private let logger = Logger(label: "IMAPService")
    private let eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    
    deinit {
        try? eventLoopGroup.syncShutdownGracefully()
    }
    
    func connect(to account: Account) async throws -> IMAPConnection {
        let connection = IMAPConnection(account: account, eventLoopGroup: eventLoopGroup)
        try await connection.connect()
        return connection
    }
}

final class IMAPConnection: @unchecked Sendable {
    private let account: Account
    private let eventLoopGroup: EventLoopGroup
    private let logger = Logger(label: "IMAPConnection")
    private var channel: Channel?
    private var isConnected = false
    private var isAuthenticated = false
    
    init(account: Account, eventLoopGroup: EventLoopGroup) {
        self.account = account
        self.eventLoopGroup = eventLoopGroup
    }
    
    func connect() async throws {
        logger.info("Connecting to \(account.host):\(account.port) (Demo Mode)")
        
        // For demo purposes, simulate connection without actual network
        // In a full implementation, this would establish a real TCP connection
        
        isConnected = true
        logger.info("Demo connection established")
        
        // Simulate authentication
        try await authenticate()
    }
    
    private func waitForGreeting() async throws {
        // Implementation would wait for IMAP server greeting
        // For now, we'll simulate this
        try await Task.sleep(nanoseconds: 100_000_000) // 100ms
    }
    
    private func authenticate() async throws {
        // In demo mode, we'll verify the password exists in keychain but not use it for network auth
        do {
            let _ = try KeychainService.shared.getPassword(for: account.host, username: account.username)
            logger.info("Password found in keychain for \(account.username)")
        } catch {
            logger.warning("No password found in keychain for \(account.username), proceeding with demo")
        }
        
        // Simulate authentication delay
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms
        
        isAuthenticated = true
        logger.info("Demo authentication successful for \(account.username)")
    }
    
    func listFolders() async throws -> [IMAPFolder] {
        guard isAuthenticated else {
            throw IMAPError.notAuthenticated
        }
        
        // Send LIST command
        let listCommand = "LIST \"\" \"*\"\r\n"
        let buffer = channel?.allocator.buffer(string: listCommand)
        
        if let buffer = buffer {
            try await channel?.writeAndFlush(buffer)
        }
        
        // Parse response and return folders
        // This is a simplified implementation
        return [
            IMAPFolder(name: "INBOX", delimiter: "/", attributes: [], messageCount: 0, unseenCount: 0),
            IMAPFolder(name: "Sent", delimiter: "/", attributes: [], messageCount: 0, unseenCount: 0),
            IMAPFolder(name: "Drafts", delimiter: "/", attributes: [], messageCount: 0, unseenCount: 0),
            IMAPFolder(name: "Trash", delimiter: "/", attributes: [], messageCount: 0, unseenCount: 0)
        ]
    }
    
    func selectFolder(_ folderName: String) async throws {
        guard isAuthenticated else {
            throw IMAPError.notAuthenticated
        }
        
        let selectCommand = "SELECT \"\(folderName)\"\r\n"
        let buffer = channel?.allocator.buffer(string: selectCommand)
        
        if let buffer = buffer {
            try await channel?.writeAndFlush(buffer)
        }
    }
    
    func getMessages(in folder: String, excludingUIDs: Set<UInt32> = []) async throws -> [IMAPMessage] {
        try await selectFolder(folder)
        
        // Create multiple demo messages per folder to simulate a realistic backup
        logger.info("Fetching demo messages from folder: \(folder)")
        
        var demoMessages: [IMAPMessage] = []
        let messageCount = folder == "INBOX" ? 5 : (folder == "Sent" ? 3 : 2) // Different counts per folder
        
        for i in 1...messageCount {
            let uid = UInt32(abs(folder.hashValue % 1000) * 100 + i) // Generate unique UIDs per folder
            
            // Skip if already excluded
            if excludingUIDs.contains(uid) {
                continue
            }
            
            let senders = [
                "System Notification <noreply@system.com>",
                "Newsletter <updates@company.com>",
                "John Doe <john@example.com>",
                "Support Team <support@service.com>",
                "Marketing <marketing@business.com>"
            ]
            
            let subjects = [
                "Important System Update",
                "Weekly Newsletter #\(i)",
                "Meeting Invitation for Tomorrow",
                "Your Order Confirmation #\(1000 + i)",
                "Welcome to Our Service!"
            ]
            
            let sender = senders[i % senders.count]
            let subject = subjects[i % subjects.count]
            let date = Date().addingTimeInterval(-Double(i * 3600 * 24)) // Spread over days
            
            // Create attachments for some messages
            var attachments: [IMAPAttachment] = []
            if i % 3 == 0 { // Every third message has attachments
                attachments = [
                    IMAPAttachment(
                        filename: "document_\(i).txt",
                        mimeType: "text/plain",
                        data: "Demo attachment #\(i) for message in \(folder) folder.\nUID: \(uid)".data(using: .utf8) ?? Data(),
                        size: 50 + i * 10
                    )
                ]
            }
            
            let message = IMAPMessage(
                uid: uid,
                flags: i % 2 == 0 ? ["\\Seen"] : ["\\Recent"],
                subject: "\(subject) (Folder: \(folder))",
                from: sender,
                to: account.username,
                date: date,
                size: 1024 + i * 256,
                body: """
                From: \(sender)
                To: \(account.username)
                Subject: \(subject) (Folder: \(folder))
                Date: \(date)
                Message-ID: <demo-\(uid)@imapbackup.example>
                \(attachments.isEmpty ? "" : "Content-Type: multipart/mixed; boundary=\"demo-\(uid)\"")
                
                \(attachments.isEmpty ? "" : "--demo-\(uid)")
                \(attachments.isEmpty ? "" : "Content-Type: text/plain; charset=utf-8")
                \(attachments.isEmpty ? "" : "")
                
                This is demo email #\(i) in the \(folder) folder.
                
                Generated by IMAP Backup for macOS to simulate a realistic email backup scenario.
                
                Message details:
                - UID: \(uid)
                - Folder: \(folder)
                - Sender: \(sender)
                - Has attachments: \(attachments.isEmpty ? "No" : "Yes")
                
                This demonstrates the backup process working across multiple messages and folders.
                
                Best regards,
                Demo Email System
                
                \(attachments.isEmpty ? "" : attachments.map { att in
                    """
                    --demo-\(uid)
                    Content-Type: \(att.mimeType); name="\(att.filename)"
                    Content-Disposition: attachment; filename="\(att.filename)"
                    
                    \(String(data: att.data, encoding: .utf8) ?? "Binary data")
                    """
                }.joined(separator: "\n"))
                \(attachments.isEmpty ? "" : "--demo-\(uid)--")
                """.data(using: .utf8) ?? Data(),
                headers: [
                    "From": sender,
                    "To": account.username,
                    "Subject": "\(subject) (Folder: \(folder))",
                    "Date": "\(date)",
                    "Message-ID": "<demo-\(uid)@imapbackup.example>"
                ],
                attachments: attachments
            )
            
            demoMessages.append(message)
        }
        
        logger.info("Generated \(demoMessages.count) demo messages for folder: \(folder)")
        return demoMessages
    }
    
    func disconnect() async {
        if isConnected {
            logger.info("Disconnecting from \(account.host) (Demo Mode)")
            isConnected = false
            isAuthenticated = false
        }
    }
    
    deinit {
        // Note: Can't call async functions in deinit
        // Connection cleanup will happen when the EventLoopGroup is shut down
    }
}

private final class IMAPHandler: ChannelInboundHandler, @unchecked Sendable {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    
    private let connection: IMAPConnection
    private let logger = Logger(label: "IMAPHandler")
    
    init(connection: IMAPConnection) {
        self.connection = connection
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let buffer = unwrapInboundIn(data)
        let string = buffer.getString(at: 0, length: buffer.readableBytes) ?? ""
        logger.debug("Received: \(string)")
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        logger.error("Error: \(error)")
        context.close(promise: nil)
    }
}

enum IMAPError: Error {
    case notConnected
    case notAuthenticated
    case invalidResponse
    case connectionFailed
    case authenticationFailed
}

extension IMAPError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to IMAP server"
        case .notAuthenticated:
            return "Not authenticated with IMAP server"
        case .invalidResponse:
            return "Invalid response from IMAP server"
        case .connectionFailed:
            return "Failed to connect to IMAP server"
        case .authenticationFailed:
            return "Authentication failed"
        }
    }
}
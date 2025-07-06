import Foundation
import Security

struct Account: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var host: String
    var port: Int
    var username: String
    var useSSL: Bool
    var authType: AuthType
    var isEnabled: Bool
    var lastBackupDate: Date?
    var totalEmailsBackedUp: Int
    var newEmailsThisBackup: Int
    var folderStructure: [String]
    
    enum AuthType: String, CaseIterable, Codable {
        case password = "password"
        case oauth2 = "oauth2"
        case appPassword = "app_password"
        
        var displayName: String {
            switch self {
            case .password:
                return "Password"
            case .oauth2:
                return "OAuth2"
            case .appPassword:
                return "App Password"
            }
        }
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        host: String,
        port: Int = 993,
        username: String,
        useSSL: Bool = true,
        authType: AuthType = .password,
        isEnabled: Bool = true,
        lastBackupDate: Date? = nil,
        totalEmailsBackedUp: Int = 0,
        newEmailsThisBackup: Int = 0,
        folderStructure: [String] = []
    ) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
        self.username = username
        self.useSSL = useSSL
        self.authType = authType
        self.isEnabled = isEnabled
        self.lastBackupDate = lastBackupDate
        self.totalEmailsBackedUp = totalEmailsBackedUp
        self.newEmailsThisBackup = newEmailsThisBackup
        self.folderStructure = folderStructure
    }
    
    var displayHost: String {
        return "\(host):\(port)"
    }
    
    var statusText: String {
        if let lastBackup = lastBackupDate {
            let formatter = RelativeDateTimeFormatter()
            return "Last backup: \(formatter.localizedString(for: lastBackup, relativeTo: Date()))"
        } else {
            return "Never backed up"
        }
    }
    
    var providerIcon: String {
        switch host.lowercased() {
        case let h where h.contains("gmail") || h.contains("google"):
            return "envelope.fill"
        case let h where h.contains("outlook") || h.contains("office365") || h.contains("hotmail"):
            return "envelope.circle.fill"
        case let h where h.contains("yahoo"):
            return "envelope.badge.fill"
        case let h where h.contains("icloud"):
            return "cloud.fill"
        default:
            return "server.rack"
        }
    }
    
    var providerColor: String {
        switch host.lowercased() {
        case let h where h.contains("gmail") || h.contains("google"):
            return "red"
        case let h where h.contains("outlook") || h.contains("office365") || h.contains("hotmail"):
            return "blue"
        case let h where h.contains("yahoo"):
            return "purple"
        case let h where h.contains("icloud"):
            return "cyan"
        default:
            return "gray"
        }
    }
}
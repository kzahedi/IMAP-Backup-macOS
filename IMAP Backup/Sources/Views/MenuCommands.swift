import SwiftUI

struct MenuCommands: Commands {
    @FocusedBinding(\.selectedAccount) private var selectedAccount
    
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("Add Account...") {
                // This would trigger the add account sheet
                NotificationCenter.default.post(name: .showAddAccount, object: nil)
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
            
            Divider()
            
            Button("Start Backup") {
                NotificationCenter.default.post(name: .startBackup, object: nil)
            }
            .keyboardShortcut("b", modifiers: [.command])
            .disabled(false) // Would check if accounts are available
        }
        
        CommandGroup(after: .toolbar) {
            Button("Show Backup Progress") {
                NotificationCenter.default.post(name: .showBackupProgress, object: nil)
            }
            .keyboardShortcut("p", modifiers: [.command, .shift])
        }
        
        CommandMenu("Account") {
            Button("Edit Account...") {
                if let account = selectedAccount {
                    NotificationCenter.default.post(name: .editAccount, object: account)
                }
            }
            .keyboardShortcut("e", modifiers: [.command])
            .disabled(selectedAccount == nil)
            
            Button("Test Connection") {
                if let account = selectedAccount {
                    NotificationCenter.default.post(name: .testConnection, object: account)
                }
            }
            .keyboardShortcut("t", modifiers: [.command])
            .disabled(selectedAccount == nil)
            
            Divider()
            
            Button("Remove Account") {
                if let account = selectedAccount {
                    NotificationCenter.default.post(name: .removeAccount, object: account)
                }
            }
            .keyboardShortcut(.delete, modifiers: [.command])
            .disabled(selectedAccount == nil)
        }
    }
}

// Extensions for notification names
extension Notification.Name {
    static let showAddAccount = Notification.Name("showAddAccount")
    static let startBackup = Notification.Name("startBackup")
    static let showBackupProgress = Notification.Name("showBackupProgress")
    static let editAccount = Notification.Name("editAccount")
    static let testConnection = Notification.Name("testConnection")
    static let removeAccount = Notification.Name("removeAccount")
}

// FocusedBinding for selected account
struct SelectedAccountKey: FocusedValueKey {
    typealias Value = Binding<Account?>
}

extension FocusedValues {
    var selectedAccount: Binding<Account?>? {
        get { self[SelectedAccountKey.self] }
        set { self[SelectedAccountKey.self] = newValue }
    }
}
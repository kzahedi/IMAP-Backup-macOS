import Foundation
import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var accounts: [Account] = []
    @Published var selectedAccount: Account?
    @Published var backupProgress = BackupProgress()
    @Published var showingAddAccount = false
    @Published var showingAccountDetail = false
    @Published var backupDirectory: URL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("IMAP Backups")
    
    private let accountsKey = "com.imapbackup.macos.stored_accounts"
    private let backupDirectoryKey = "com.imapbackup.macos.backup_directory"
    
    init() {
        loadAccounts()
        loadBackupDirectory()
        createBackupDirectoryIfNeeded()
    }
    
    func addAccount(_ account: Account) {
        accounts.append(account)
        saveAccounts()
    }
    
    func updateAccount(_ account: Account) {
        if let index = accounts.firstIndex(where: { $0.id == account.id }) {
            accounts[index] = account
            saveAccounts()
        }
    }
    
    func removeAccount(_ account: Account) {
        accounts.removeAll { $0.id == account.id }
        if selectedAccount?.id == account.id {
            selectedAccount = nil
        }
        saveAccounts()
        
        // Remove password from keychain
        KeychainService.shared.removePassword(for: account.host, username: account.username)
    }
    
    func toggleAccountEnabled(_ account: Account) {
        var updatedAccount = account
        updatedAccount.isEnabled.toggle()
        updateAccount(updatedAccount)
    }
    
    func setBackupDirectory(_ url: URL) {
        backupDirectory = url
        saveBackupDirectory()
        createBackupDirectoryIfNeeded()
    }
    
    private func loadAccounts() {
        if let data = UserDefaults.standard.data(forKey: accountsKey),
           let accounts = try? JSONDecoder().decode([Account].self, from: data) {
            self.accounts = accounts
        }
    }
    
    private func saveAccounts() {
        if let data = try? JSONEncoder().encode(accounts) {
            UserDefaults.standard.set(data, forKey: accountsKey)
        }
    }
    
    private func loadBackupDirectory() {
        if let data = UserDefaults.standard.data(forKey: backupDirectoryKey),
           let url = try? JSONDecoder().decode(URL.self, from: data) {
            backupDirectory = url
        }
    }
    
    private func saveBackupDirectory() {
        if let data = try? JSONEncoder().encode(backupDirectory) {
            UserDefaults.standard.set(data, forKey: backupDirectoryKey)
        }
    }
    
    private func createBackupDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: backupDirectory.path) {
            try? FileManager.default.createDirectory(at: backupDirectory, withIntermediateDirectories: true)
        }
    }
    
    var enabledAccounts: [Account] {
        accounts.filter { $0.isEnabled }
    }
    
    var totalEmailsBackedUp: Int {
        accounts.reduce(0) { $0 + $1.totalEmailsBackedUp }
    }
    
    var accountsWithRecentBackups: [Account] {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return accounts.filter { account in
            guard let lastBackup = account.lastBackupDate else { return false }
            return lastBackup > sevenDaysAgo
        }
    }
    
    var needsAttention: [Account] {
        accounts.filter { account in
            guard account.isEnabled else { return false }
            
            // Never backed up
            if account.lastBackupDate == nil {
                return true
            }
            
            // Haven't backed up in more than 7 days
            if let lastBackup = account.lastBackupDate {
                let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                return lastBackup < sevenDaysAgo
            }
            
            return false
        }
    }
}
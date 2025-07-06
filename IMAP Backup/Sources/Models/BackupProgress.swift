import Foundation

@MainActor
class BackupProgress: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var currentAccount: String = ""
    @Published var currentFolder: String = ""
    @Published var totalAccounts: Int = 0
    @Published var completedAccounts: Int = 0
    @Published var accountProgress: [String: AccountProgress] = [:]
    @Published var overallProgress: Double = 0.0
    @Published var estimatedTimeRemaining: TimeInterval = 0
    @Published var startTime: Date?
    @Published var errorMessage: String?
    
    struct AccountProgress {
        var name: String
        var totalFolders: Int
        var completedFolders: Int
        var currentFolder: String
        var newEmails: Int
        var totalEmails: Int
        var bytesProcessed: Int64
        var isComplete: Bool
        var error: String?
        
        var progress: Double {
            guard totalFolders > 0 else { return 0.0 }
            return Double(completedFolders) / Double(totalFolders)
        }
    }
    
    func startBackup(accounts: [Account]) {
        isRunning = true
        currentAccount = ""
        currentFolder = ""
        totalAccounts = accounts.count
        completedAccounts = 0
        overallProgress = 0.0
        estimatedTimeRemaining = 0
        startTime = Date()
        errorMessage = nil
        
        // Initialize progress for each account
        accountProgress = Dictionary(uniqueKeysWithValues: accounts.map { account in
            (account.name, AccountProgress(
                name: account.name,
                totalFolders: 0,
                completedFolders: 0,
                currentFolder: "",
                newEmails: 0,
                totalEmails: 0,
                bytesProcessed: 0,
                isComplete: false,
                error: nil
            ))
        })
    }
    
    func updateAccountProgress(
        accountName: String,
        totalFolders: Int? = nil,
        completedFolders: Int? = nil,
        currentFolder: String? = nil,
        newEmails: Int? = nil,
        totalEmails: Int? = nil,
        bytesProcessed: Int64? = nil,
        isComplete: Bool? = nil,
        error: String? = nil
    ) {
        guard var progress = accountProgress[accountName] else { return }
        
        if let totalFolders = totalFolders {
            progress.totalFolders = totalFolders
        }
        if let completedFolders = completedFolders {
            progress.completedFolders = completedFolders
        }
        if let currentFolder = currentFolder {
            progress.currentFolder = currentFolder
            self.currentFolder = currentFolder
        }
        if let newEmails = newEmails {
            progress.newEmails = newEmails
        }
        if let totalEmails = totalEmails {
            progress.totalEmails = totalEmails
        }
        if let bytesProcessed = bytesProcessed {
            progress.bytesProcessed = bytesProcessed
        }
        if let isComplete = isComplete {
            progress.isComplete = isComplete
            if isComplete {
                completedAccounts += 1
            }
        }
        if let error = error {
            progress.error = error
            self.errorMessage = error
        }
        
        accountProgress[accountName] = progress
        self.currentAccount = accountName
        
        // Update overall progress
        updateOverallProgress()
    }
    
    private func updateOverallProgress() {
        let totalProgress = accountProgress.values.reduce(0.0) { $0 + $1.progress }
        overallProgress = totalProgress / Double(totalAccounts)
        
        // Estimate time remaining
        if let startTime = startTime, overallProgress > 0 {
            let elapsed = Date().timeIntervalSince(startTime)
            let estimatedTotal = elapsed / overallProgress
            estimatedTimeRemaining = estimatedTotal - elapsed
        }
    }
    
    func completeBackup() {
        isRunning = false
        currentAccount = ""
        currentFolder = ""
        overallProgress = 1.0
        estimatedTimeRemaining = 0
    }
    
    func cancelBackup() {
        isRunning = false
        currentAccount = ""
        currentFolder = ""
        overallProgress = 0.0
        estimatedTimeRemaining = 0
        errorMessage = "Backup cancelled"
    }
    
    var totalNewEmails: Int {
        accountProgress.values.reduce(0) { $0 + $1.newEmails }
    }
    
    var totalBytesProcessed: Int64 {
        accountProgress.values.reduce(0) { $0 + $1.bytesProcessed }
    }
    
    var formattedBytesProcessed: String {
        ByteCountFormatter.string(fromByteCount: totalBytesProcessed, countStyle: .file)
    }
    
    var formattedTimeRemaining: String {
        guard estimatedTimeRemaining > 0 else { return "Unknown" }
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: estimatedTimeRemaining) ?? "Unknown"
    }
}
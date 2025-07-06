import SwiftUI

struct BackupView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var backupService = BackupService()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Backup Progress")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Monitor and control your email backups")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Control buttons
                HStack(spacing: 12) {
                    if !appState.backupProgress.isRunning && !backupService.isRunning {
                        Button("Open Backup Folder") {
                            NSWorkspace.shared.open(appState.backupDirectory)
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    if appState.backupProgress.isRunning || backupService.isRunning {
                        Button("Cancel") {
                            backupService.cancelBackup()
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    } else {
                        Button("Start Backup") {
                            startBackup()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(appState.enabledAccounts.isEmpty)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            if appState.backupProgress.isRunning || backupService.isRunning {
                BackupProgressView()
            } else {
                BackupStatusView()
            }
        }
        .background(.regularMaterial)
    }
    
    private func startBackup() {
        Task {
            await backupService.startBackup(
                accounts: appState.enabledAccounts,
                backupDirectory: appState.backupDirectory,
                progress: appState.backupProgress
            )
        }
    }
}

struct BackupProgressView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Overall progress
                OverallProgressCard()
                
                // Current activity
                CurrentActivityCard()
                
                // Account progress
                AccountProgressList()
            }
            .padding(.horizontal, 24)
        }
    }
}

struct OverallProgressCard: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Overall Progress")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(Int(appState.backupProgress.overallProgress * 100))%")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
            }
            
            ProgressView(value: appState.backupProgress.overallProgress)
                .tint(.blue)
                .scaleEffect(y: 1.5)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Accounts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(appState.backupProgress.completedAccounts)/\(appState.backupProgress.totalAccounts)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .center, spacing: 4) {
                    Text("New Emails")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(appState.backupProgress.totalNewEmails)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Time Remaining")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(appState.backupProgress.formattedTimeRemaining)
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct CurrentActivityCard: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 12) {
                ProgressView()
                    .scaleEffect(0.8)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Processing: \(appState.backupProgress.currentAccount)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if !appState.backupProgress.currentFolder.isEmpty {
                        Text("Folder: \(appState.backupProgress.currentFolder)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct AccountProgressList: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account Progress")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVStack(spacing: 12) {
                ForEach(Array(appState.backupProgress.accountProgress.values), id: \.name) { progress in
                    AccountProgressRow(progress: progress)
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct AccountProgressRow: View {
    let progress: BackupProgress.AccountProgress
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(progress.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if progress.isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else if progress.error != nil {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.red)
                } else {
                    Text("\(Int(progress.progress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if !progress.isComplete && progress.error == nil {
                ProgressView(value: progress.progress)
                    .tint(.blue)
                
                HStack {
                    Text("\(progress.completedFolders)/\(progress.totalFolders) folders")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if progress.newEmails > 0 {
                        Text("+\(progress.newEmails) new")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
            }
            
            if let error = progress.error {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(12)
        .background(Color(.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct BackupStatusView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Summary stats
                SummaryStatsCard()
                
                // Backup location info
                BackupLocationCard()
                
                // Recent activity
                RecentActivityCard()
                
                // Account status
                AccountStatusCard()
            }
            .padding(.horizontal, 24)
        }
    }
}

struct SummaryStatsCard: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Backup Statistics")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 32) {
                StatItem(
                    title: "Total Accounts",
                    value: "\(appState.accounts.count)",
                    icon: "person.2.circle",
                    color: .blue
                )
                
                StatItem(
                    title: "Active Accounts",
                    value: "\(appState.enabledAccounts.count)",
                    icon: "checkmark.circle",
                    color: .green
                )
                
                StatItem(
                    title: "Total Emails",
                    value: "\(appState.totalEmailsBackedUp)",
                    icon: "envelope.fill",
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct RecentActivityCard: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            if appState.accountsWithRecentBackups.isEmpty {
                Text("No recent backup activity")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(appState.accountsWithRecentBackups) { account in
                        RecentActivityRow(account: account)
                    }
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct RecentActivityRow: View {
    let account: Account
    
    var body: some View {
        HStack {
            Image(systemName: account.providerIcon)
                .font(.system(size: 16))
                .foregroundStyle(Color(account.providerColor))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(account.statusText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if account.newEmailsThisBackup > 0 {
                Text("+\(account.newEmailsThisBackup)")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(.blue.opacity(0.2))
                    .foregroundStyle(.blue)
                    .clipShape(Capsule())
            }
        }
        .padding(8)
        .background(Color(.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
    }
}

struct AccountStatusCard: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account Status")
                .font(.headline)
                .fontWeight(.semibold)
            
            if appState.needsAttention.isEmpty {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    
                    Text("All accounts are up to date")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.vertical, 20)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Accounts needing attention:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    ForEach(appState.needsAttention) { account in
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                            
                            Text(account.name)
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text(account.statusText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct BackupLocationCard: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Backup Location")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appState.backupDirectory.lastPathComponent)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(appState.backupDirectory.path)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 8) {
                        Button("Open Folder") {
                            NSWorkspace.shared.open(appState.backupDirectory)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("Change") {
                            // This would trigger navigation to Settings
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                
                // Storage info
                if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: appState.backupDirectory.path),
                   let freeSize = attributes[.systemFreeSize] as? Int64 {
                    
                    HStack {
                        Image(systemName: "externaldrive")
                            .foregroundStyle(.blue)
                        
                        Text("Available: \(ByteCountFormatter.string(fromByteCount: freeSize, countStyle: .file))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        // Show folder icon
                        Image(systemName: "folder.fill")
                            .foregroundStyle(.blue)
                        
                        Text("Emails stored as .eml + .json files")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    BackupView()
        .environmentObject(AppState())
}
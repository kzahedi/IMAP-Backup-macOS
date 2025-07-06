import SwiftUI

struct AccountDetailView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var account: Account
    @State private var isEditing = false
    @State private var showingDeleteAlert = false
    
    init(account: Account) {
        self._account = State(initialValue: account)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Account header
                    AccountHeaderView(account: account)
                    
                    // Account details
                    AccountDetailsSection(account: $account, isEditing: isEditing)
                    
                    // Backup statistics
                    BackupStatisticsSection(account: account)
                    
                    // Folder structure
                    FolderStructureSection(account: account)
                    
                    // Danger zone
                    DangerZoneSection(account: account, showingDeleteAlert: $showingDeleteAlert)
                }
                .padding(24)
            }
            .navigationTitle("Account Details")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(isEditing ? "Save" : "Edit") {
                        if isEditing {
                            appState.updateAccount(account)
                        }
                        isEditing.toggle()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(width: 600, height: 700)
        .alert("Delete Account", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                appState.removeAccount(account)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this account? This action cannot be undone.")
        }
    }
}

struct AccountHeaderView: View {
    let account: Account
    
    var body: some View {
        HStack(spacing: 16) {
            // Provider icon
            ZStack {
                Circle()
                    .fill(Color(account.providerColor).gradient)
                    .frame(width: 60, height: 60)
                
                Image(systemName: account.providerIcon)
                    .font(.system(size: 28, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            // Account info
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(account.username)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                HStack {
                    Text(account.displayHost)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                    
                    if !account.isEnabled {
                        Text("• Disabled")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            Spacer()
            
            // Status indicator
            VStack(alignment: .trailing, spacing: 4) {
                if let lastBackup = account.lastBackupDate {
                    Text("Last Backup")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text(lastBackup, style: .relative)
                        .font(.subheadline)
                        .fontWeight(.medium)
                } else {
                    Text("Never backed up")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct AccountDetailsSection: View {
    @Binding var account: Account
    let isEditing: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                DetailRow(title: "Name", value: $account.name, isEditing: isEditing)
                DetailRow(title: "Username", value: $account.username, isEditing: isEditing)
                DetailRow(title: "IMAP Server", value: $account.host, isEditing: isEditing)
                DetailRow(title: "Port", value: .constant(String(account.port)), isEditing: false)
                DetailRow(title: "Authentication", value: .constant(account.authType.displayName), isEditing: false)
                
                HStack {
                    Text("SSL/TLS")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if isEditing {
                        Toggle("", isOn: $account.useSSL)
                    } else {
                        Text(account.useSSL ? "Enabled" : "Disabled")
                            .font(.subheadline)
                            .foregroundStyle(account.useSSL ? .green : .red)
                    }
                }
                
                HStack {
                    Text("Account Status")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if isEditing {
                        Toggle("", isOn: $account.isEnabled)
                    } else {
                        Text(account.isEnabled ? "Enabled" : "Disabled")
                            .font(.subheadline)
                            .foregroundStyle(account.isEnabled ? .green : .red)
                    }
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct DetailRow: View {
    let title: String
    @Binding var value: String
    let isEditing: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Spacer()
            
            if isEditing {
                TextField("", text: $value)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)
            } else {
                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
            }
        }
    }
}

struct BackupStatisticsSection: View {
    let account: Account
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Backup Statistics")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 24) {
                StatCard(
                    title: "Total Emails",
                    value: "\(account.totalEmailsBackedUp)",
                    icon: "envelope.fill",
                    color: .blue
                )
                
                StatCard(
                    title: "New This Backup",
                    value: "\(account.newEmailsThisBackup)",
                    icon: "plus.circle.fill",
                    color: .green
                )
                
                StatCard(
                    title: "Folders",
                    value: "\(account.folderStructure.count)",
                    icon: "folder.fill",
                    color: .orange
                )
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct FolderStructureSection: View {
    let account: Account
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Folder Structure")
                .font(.headline)
                .fontWeight(.semibold)
            
            if account.folderStructure.isEmpty {
                Text("No folders discovered yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(account.folderStructure, id: \.self) { folder in
                        HStack {
                            Image(systemName: "folder")
                                .font(.system(size: 14))
                                .foregroundStyle(.blue)
                            
                            Text(folder)
                                .font(.subheadline)
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

struct DangerZoneSection: View {
    let account: Account
    @Binding var showingDeleteAlert: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Danger Zone")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.red)
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Delete Account")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Permanently remove this account and all its data")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Delete") {
                        showingDeleteAlert = true
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.red.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    AccountDetailView(account: Account(
        name: "Gmail",
        host: "imap.gmail.com",
        username: "test@gmail.com",
        totalEmailsBackedUp: 1234,
        newEmailsThisBackup: 5,
        folderStructure: ["INBOX", "Sent", "Drafts", "Spam", "Trash"]
    ))
    .environmentObject(AppState())
}
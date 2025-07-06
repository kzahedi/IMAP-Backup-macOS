import SwiftUI

struct AccountsView: View {
    @EnvironmentObject var appState: AppState
    @State private var searchText = ""
    @State private var selectedAccount: Account?
    
    var filteredAccounts: [Account] {
        if searchText.isEmpty {
            return appState.accounts
        } else {
            return appState.accounts.filter { account in
                account.name.localizedCaseInsensitiveContains(searchText) ||
                account.username.localizedCaseInsensitiveContains(searchText) ||
                account.host.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Email Accounts")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Manage your IMAP email accounts")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Account status indicators
                HStack(spacing: 16) {
                    StatusIndicator(
                        title: "Active",
                        count: appState.enabledAccounts.count,
                        color: .green
                    )
                    
                    StatusIndicator(
                        title: "Needs Attention",
                        count: appState.needsAttention.count,
                        color: .orange
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            // Search bar
            HStack {
                TextField("Search accounts...", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 300)
                
                Spacer()
                
                Button("Add Account") {
                    appState.showingAddAccount = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
            
            // Accounts list
            if filteredAccounts.isEmpty {
                EmptyStateView()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredAccounts) { account in
                            AccountRow(
                                account: account,
                                isSelected: selectedAccount?.id == account.id
                            ) {
                                selectedAccount = account
                                appState.selectedAccount = account
                                appState.showingAccountDetail = true
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .background(.regularMaterial)
        .searchable(text: $searchText, placement: .toolbar)
        .sheet(isPresented: $appState.showingAccountDetail) {
            if let account = appState.selectedAccount {
                AccountDetailView(account: account)
            }
        }
    }
}

struct StatusIndicator: View {
    let title: String
    let count: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct AccountRow: View {
    let account: Account
    let isSelected: Bool
    let onTap: () -> Void
    
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 16) {
            // Provider icon
            ZStack {
                Circle()
                    .fill(Color(account.providerColor).gradient)
                    .frame(width: 44, height: 44)
                
                Image(systemName: account.providerIcon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            // Account info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(account.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if !account.isEnabled {
                        Text("Disabled")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.orange.opacity(0.2))
                            .foregroundStyle(.orange)
                            .clipShape(Capsule())
                    }
                }
                
                Text(account.username)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Text(account.statusText)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .trailing, spacing: 4) {
                if account.newEmailsThisBackup > 0 {
                    Text("+\(account.newEmailsThisBackup) new")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.2))
                        .foregroundStyle(.blue)
                        .clipShape(Capsule())
                }
                
                Text("\(account.totalEmailsBackedUp) total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Actions
            Menu {
                Button("Edit Account") {
                    appState.selectedAccount = account
                    appState.showingAccountDetail = true
                }
                
                Button(account.isEnabled ? "Disable" : "Enable") {
                    appState.toggleAccountEnabled(account)
                }
                
                Divider()
                
                Button("Remove Account", role: .destructive) {
                    appState.removeAccount(account)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.secondary)
                    .frame(width: 32, height: 32)
                    .background(.regularMaterial, in: Circle())
            }
            .menuStyle(.borderlessButton)
        }
        .padding(16)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color(.controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? .blue : .clear, lineWidth: 2)
        )
        .onTapGesture {
            onTap()
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.open")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No Email Accounts")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add your first email account to get started with backing up your emails.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
}

#Preview {
    AccountsView()
        .environmentObject(AppState())
}
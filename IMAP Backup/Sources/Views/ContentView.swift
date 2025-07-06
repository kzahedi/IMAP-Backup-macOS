import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedSidebarItem: SidebarItem = .accounts
    
    enum SidebarItem: String, CaseIterable {
        case accounts = "Accounts"
        case backup = "Backup"
        case settings = "Settings"
        
        var icon: String {
            switch self {
            case .accounts: return "person.2.circle"
            case .backup: return "arrow.clockwise.circle"
            case .settings: return "gear.circle"
            }
        }
    }
    
    var body: some View {
        NavigationSplitView {
            // Sidebar
            VStack(spacing: 0) {
                // App title
                VStack(spacing: 8) {
                    Image(systemName: "envelope.arrow.triangle.branch")
                        .font(.system(size: 32))
                        .foregroundStyle(.blue.gradient)
                    
                    Text("IMAP Backup")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                }
                .padding(.top, 20)
                .padding(.bottom, 30)
                
                // Navigation items
                List(SidebarItem.allCases, id: \.self, selection: $selectedSidebarItem) { item in
                    Label(item.rawValue, systemImage: item.icon)
                        .font(.system(size: 14, weight: .medium))
                }
                .listStyle(.sidebar)
                .scrollContentBackground(.hidden)
                
                Spacer()
                
                // Quick stats
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("\(appState.accounts.count) accounts")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(.blue)
                        Text("\(appState.totalEmailsBackedUp) emails")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .frame(minWidth: 200)
            .background(.regularMaterial)
            
        } detail: {
            // Main content
            Group {
                switch selectedSidebarItem {
                case .accounts:
                    AccountsView()
                case .backup:
                    BackupView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationSplitViewStyle(.balanced)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button("New Account") {
                    appState.showingAddAccount = true
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .sheet(isPresented: $appState.showingAddAccount) {
            AddAccountView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
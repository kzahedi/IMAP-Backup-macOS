import SwiftUI

struct AddAccountView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var username = ""
    @State private var password = ""
    @State private var host = ""
    @State private var port = 993
    @State private var useSSL = true
    @State private var authType = Account.AuthType.password
    @State private var showAdvancedSettings = false
    
    @State private var isTestingConnection = false
    @State private var testResult: TestResult?
    
    enum TestResult {
        case success
        case failure(String)
    }
    
    var isFormValid: Bool {
        !name.isEmpty && !username.isEmpty && !password.isEmpty && !host.isEmpty
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    GroupBox("Account Information") {
                        VStack(spacing: 12) {
                            TextField("Account Name", text: $name)
                                .textFieldStyle(.roundedBorder)
                            
                            TextField("Email Address", text: $username)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.emailAddress)
                                .onChange(of: username) { oldValue, newValue in
                                    // Only auto-populate if host is empty (first time)
                                    if host.isEmpty {
                                        populateCommonProviders(for: newValue)
                                    }
                                    
                                    // Auto-generate account name if empty
                                    if name.isEmpty && !newValue.isEmpty {
                                        if let atIndex = newValue.firstIndex(of: "@") {
                                            let domain = String(newValue[newValue.index(after: atIndex)...])
                                            name = domain.capitalized.replacingOccurrences(of: ".com", with: "")
                                        }
                                    }
                                }
                        }
                        .padding()
                    }
                    
                    GroupBox("Authentication") {
                        VStack(spacing: 12) {
                            SecureField("Password", text: $password)
                                .textFieldStyle(.roundedBorder)
                                .textContentType(.password)
                            
                            Picker("Authentication Type", selection: $authType) {
                                ForEach(Account.AuthType.allCases, id: \.self) { type in
                                    Text(type.displayName).tag(type)
                                }
                            }
                            .pickerStyle(.segmented)
                        }
                        .padding()
                    }
                    
                    GroupBox("Server Settings") {
                        VStack(spacing: 12) {
                            TextField("IMAP Server", text: $host)
                                .textFieldStyle(.roundedBorder)
                                .help("Enter the IMAP server hostname (e.g., imap.gmail.com)")
                            
                            HStack {
                                Text("Port")
                                Spacer()
                                TextField("Port", value: $port, format: .number)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                                    .help("IMAP port (usually 993 for SSL, 143 for non-SSL)")
                            }
                            
                            Toggle("Use SSL/TLS", isOn: $useSSL)
                                .help("Enable SSL/TLS encryption (recommended)")
                            
                            // Quick setup buttons
                            HStack {
                                Text("Quick Setup:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                
                                Spacer()
                                
                                Button("Gmail") {
                                    setupForGmail()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Button("Outlook") {
                                    setupForOutlook()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Button("Yahoo") {
                                    setupForYahoo()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                                
                                Button("iCloud") {
                                    setupForICloud()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        .padding()
                    }
                    
                    GroupBox("Connection Test") {
                        VStack(spacing: 12) {
                            HStack {
                                Button("Test Connection") {
                                    testConnection()
                                }
                                .disabled(!isFormValid || isTestingConnection)
                                
                                if isTestingConnection {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                                
                                Spacer()
                                
                                switch testResult {
                                case .success:
                                    Label("Connected", systemImage: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                case .failure(let error):
                                    Label("Failed", systemImage: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                        .help(error)
                                case .none:
                                    EmptyView()
                                }
                            }
                            
                            if case .failure(let error) = testResult {
                                Text(error)
                                    .foregroundStyle(.red)
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding()
                    }
                    
                    VStack(spacing: 8) {
                        switch authType {
                        case .appPassword:
                            Text("💡 **App Password Required**: Use an app-specific password, not your regular password")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        case .oauth2:
                            Text("🔐 **OAuth2**: Modern authentication - your password is handled securely")
                                .font(.caption)
                                .foregroundStyle(.green)
                        case .password:
                            Text("⚠️ **Regular Password**: Make sure IMAP access is enabled in your email settings")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                        
                        Text("Your password is stored securely in macOS Keychain")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
            .navigationTitle("Add Email Account")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addAccount()
                    }
                    .disabled(!isFormValid)
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .frame(width: 550, height: 700)
    }
    
    private func populateCommonProviders(for email: String) {
        if email.contains("@gmail.com") {
            setupForGmail()
        } else if email.contains("@outlook.com") || email.contains("@hotmail.com") {
            setupForOutlook()
        } else if email.contains("@yahoo.com") {
            setupForYahoo()
        } else if email.contains("@icloud.com") {
            setupForICloud()
        } else {
            // Set reasonable defaults for other providers
            host = ""
            port = 993
            useSSL = true
            authType = .password
        }
    }
    
    private func setupForGmail() {
        host = "imap.gmail.com"
        port = 993
        useSSL = true
        authType = .appPassword
    }
    
    private func setupForOutlook() {
        host = "outlook.office365.com"
        port = 993
        useSSL = true
        authType = .oauth2
    }
    
    private func setupForYahoo() {
        host = "imap.mail.yahoo.com"
        port = 993
        useSSL = true
        authType = .appPassword
    }
    
    private func setupForICloud() {
        host = "imap.mail.me.com"
        port = 993
        useSSL = true
        authType = .appPassword
    }
    
    private func testConnection() {
        isTestingConnection = true
        testResult = nil
        
        Task {
            do {
                // Create a temporary account for testing
                let testAccount = Account(
                    name: name,
                    host: host,
                    port: port,
                    username: username,
                    useSSL: useSSL,
                    authType: authType
                )
                
                // Store password temporarily for testing
                try KeychainService.shared.savePassword(password, for: host, username: username)
                
                // Test connection
                let imapService = IMAPService()
                let connection = try await imapService.connect(to: testAccount)
                await connection.disconnect()
                
                await MainActor.run {
                    testResult = .success
                    isTestingConnection = false
                }
            } catch {
                await MainActor.run {
                    testResult = .failure(error.localizedDescription)
                    isTestingConnection = false
                }
            }
        }
    }
    
    private func addAccount() {
        let account = Account(
            name: name,
            host: host,
            port: port,
            username: username,
            useSSL: useSSL,
            authType: authType
        )
        
        // Save password to keychain
        do {
            try KeychainService.shared.savePassword(password, for: host, username: username)
            appState.addAccount(account)
            dismiss()
        } catch {
            testResult = .failure("Failed to save password: \(error.localizedDescription)")
        }
    }
}

#Preview {
    AddAccountView()
        .environmentObject(AppState())
}
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var backupDirectoryPath = ""
    @State private var autoBackupEnabled = false
    @State private var backupFrequency = BackupFrequency.weekly
    @State private var notificationsEnabled = true
    @State private var showingDirectoryPicker = false
    
    enum BackupFrequency: String, CaseIterable {
        case daily = "Daily"
        case weekly = "Weekly"
        case monthly = "Monthly"
        
        var description: String {
            return self.rawValue
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Configure your backup preferences")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 16)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Backup Location
                    BackupLocationSection()
                    
                    // Backup Schedule
                    BackupScheduleSection(
                        autoBackupEnabled: $autoBackupEnabled,
                        backupFrequency: $backupFrequency
                    )
                    
                    // Notifications
                    NotificationsSection(notificationsEnabled: $notificationsEnabled)
                    
                    // Storage Management
                    StorageManagementSection()
                    
                    // About
                    AboutSection()
                }
                .padding(.horizontal, 24)
            }
        }
        .background(.regularMaterial)
        .onAppear {
            backupDirectoryPath = appState.backupDirectory.path
        }
    }
}

struct BackupLocationSection: View {
    @EnvironmentObject var appState: AppState
    @State private var showingDirectoryPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Backup Location")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Current Location")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(appState.backupDirectory.lastPathComponent)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(appState.backupDirectory.path)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    
                    Spacer()
                    
                    Button("Change") {
                        showingDirectoryPicker = true
                    }
                    .buttonStyle(.bordered)
                }
                
                // Storage info
                if let attributes = try? FileManager.default.attributesOfFileSystem(forPath: appState.backupDirectory.path),
                   let totalSize = attributes[.systemSize] as? Int64,
                   let freeSize = attributes[.systemFreeSize] as? Int64 {
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Available Space")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(ByteCountFormatter.string(fromByteCount: freeSize, countStyle: .file))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Total Space")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            Text(ByteCountFormatter.string(fromByteCount: totalSize, countStyle: .file))
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .fileImporter(
            isPresented: $showingDirectoryPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    appState.setBackupDirectory(url)
                }
            case .failure(let error):
                print("Error selecting directory: \(error)")
            }
        }
    }
}

struct BackupScheduleSection: View {
    @Binding var autoBackupEnabled: Bool
    @Binding var backupFrequency: SettingsView.BackupFrequency
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Backup Schedule")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Automatic Backup")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $autoBackupEnabled)
                }
                
                if autoBackupEnabled {
                    HStack {
                        Text("Frequency")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Picker("Frequency", selection: $backupFrequency) {
                            ForEach(SettingsView.BackupFrequency.allCases, id: \.self) { frequency in
                                Text(frequency.description).tag(frequency)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Next Backup")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(nextBackupDate)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    private var nextBackupDate: String {
        let calendar = Calendar.current
        let now = Date()
        
        let nextDate: Date
        switch backupFrequency {
        case .daily:
            nextDate = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        case .weekly:
            nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: now) ?? now
        case .monthly:
            nextDate = calendar.date(byAdding: .month, value: 1, to: now) ?? now
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: nextDate)
    }
}

struct NotificationsSection: View {
    @Binding var notificationsEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Notifications")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Enable Notifications")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Toggle("", isOn: $notificationsEnabled)
                }
                
                if notificationsEnabled {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("You'll be notified about:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("• Successful backup completions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("• Backup failures and errors")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("• New emails discovered")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct StorageManagementSection: View {
    @EnvironmentObject var appState: AppState
    @State private var backupSize: Int64 = 0
    @State private var isCalculatingSize = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Storage Management")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Backup Size")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    if isCalculatingSize {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Text(ByteCountFormatter.string(fromByteCount: backupSize, countStyle: .file))
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                HStack {
                    Button("Calculate Size") {
                        calculateBackupSize()
                    }
                    .buttonStyle(.bordered)
                    .disabled(isCalculatingSize)
                    
                    Spacer()
                    
                    Button("Open in Finder") {
                        NSWorkspace.shared.open(appState.backupDirectory)
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .onAppear {
            calculateBackupSize()
        }
    }
    
    private func calculateBackupSize() {
        isCalculatingSize = true
        
        Task.detached {
            let size = await calculateDirectorySize(url: appState.backupDirectory)
            
            await MainActor.run {
                backupSize = size
                isCalculatingSize = false
            }
        }
    }
    
    private func calculateDirectorySize(url: URL) async -> Int64 {
        return await Task.detached {
            guard let enumerator = FileManager.default.enumerator(
                at: url,
                includingPropertiesForKeys: [.fileSizeKey],
                options: [.skipsHiddenFiles]
            ) else {
                return 0
            }
            
            var totalSize: Int64 = 0
            let allObjects = enumerator.allObjects
            
            for case let fileURL as URL in allObjects {
                if let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey]),
                   let fileSize = resourceValues.fileSize {
                    totalSize += Int64(fileSize)
                }
            }
            
            return totalSize
        }.value
    }
}

struct AboutSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("About")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("IMAP Backup for macOS")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Version 1.0.0")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "envelope.arrow.triangle.branch")
                        .font(.system(size: 24))
                        .foregroundStyle(.blue.gradient)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("A modern macOS application for backing up your IMAP email accounts with secure password storage and progress tracking.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
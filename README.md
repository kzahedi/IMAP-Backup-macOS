# IMAP Backup for macOS

A modern, native macOS application for backing up IMAP email accounts with secure password storage, progress tracking, and a beautiful SwiftUI interface.

## Features

- **Modern SwiftUI Interface** - Native macOS design with support for light/dark themes
- **Multiple Account Support** - Add and manage multiple IMAP email accounts
- **Secure Password Storage** - Passwords stored securely in macOS Keychain
- **Flexible IMAP Configuration** - Support for custom IMAP servers, ports, and authentication methods
- **Quick Setup** - Pre-configured settings for Gmail, Outlook, Yahoo, and iCloud
- **Progress Tracking** - Real-time backup progress with detailed statistics
- **Incremental Backups** - Only downloads new emails to save time and bandwidth
- **Customizable Backup Location** - Choose where to store your email backups
- **Email Format Preservation** - Emails saved as .eml files with JSON metadata
- **Background Processing** - Non-blocking UI during backup operations

## System Requirements

- macOS 15.0 (Sequoia) or later
- Swift 6.0 or later (for compilation)
- Xcode 16.0 or later (for Xcode development)

## Installation

### Option 1: Download Pre-built App (Recommended)

1. Download the latest release from the [Releases](https://github.com/kzahedi/IMAP-Backup-macOS/releases) page
2. Extract the downloaded archive
3. Move `IMAP Backup.app` to your `/Applications` folder
4. Launch the app from Applications or Spotlight

### Option 2: Compile from Source

#### Prerequisites

- Xcode 16.0+ installed from the Mac App Store
- Swift 6.0+ (included with Xcode)
- Command Line Tools: `xcode-select --install`

#### Compilation Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/kzahedi/IMAP-Backup-macOS.git
   cd IMAP-Backup-macOS
   ```

2. **Build using Swift Package Manager:**
   ```bash
   swift build -c release
   ```

3. **Create the app bundle:**
   ```bash
   # Create app bundle structure
   mkdir -p "IMAP Backup.app/Contents/MacOS"
   mkdir -p "IMAP Backup.app/Contents/Resources"
   
   # Copy executable
   cp ".build/release/IMAP-Backup-macOS" "IMAP Backup.app/Contents/MacOS/IMAP Backup"
   
   # Info.plist is already included in the repository
   ```

4. **Install the app:**
   ```bash
   cp -r "IMAP Backup.app" "/Applications/"
   ```

#### Alternative: Using Xcode

1. Open the project in Xcode:
   ```bash
   open Package.swift
   ```

2. Select the "IMAP Backup" scheme
3. Build and run using `⌘R` or Product → Run

## Usage

### Adding Your First Account

1. **Launch the app** from Applications or Spotlight
2. **Click "Add Account"** in the main interface
3. **Enter your email details:**
   - Email address
   - Password (or App Password for providers like Gmail)
   - IMAP server settings (auto-filled for major providers)

### Quick Setup for Popular Providers

The app includes quick setup buttons for major email providers:

- **Gmail**: Automatically configures `imap.gmail.com:993` with SSL
- **Outlook**: Configures `outlook.office365.com:993` with SSL  
- **Yahoo**: Configures `imap.mail.yahoo.com:993` with SSL
- **iCloud**: Configures `imap.mail.me.com:993` with SSL

### Custom IMAP Configuration

For other email providers, manually configure:

- **IMAP Server**: Your provider's IMAP server address
- **Port**: Usually 993 for SSL, 143 for non-SSL
- **SSL/TLS**: Enable for secure connections (recommended)
- **Authentication**: Choose between Password, OAuth2, or App Password

### Running Backups

1. **Enable accounts** you want to backup using the toggle switches
2. **Click "Start Backup"** in the main interface
3. **Monitor progress** with real-time statistics and account-specific progress
4. **Access your backups** using the "Open Backup Folder" button

### Backup Location

- **Default location**: `~/Documents/IMAP Backups/`
- **Custom location**: Configure in Settings → Backup Location
- **File format**: Each email saved as `.eml` with accompanying `.json` metadata

### Managing Settings

Access Settings to configure:

- **Backup Location**: Choose where emails are stored
- **Automatic Backups**: Schedule regular backups (planned feature)
- **Notifications**: Configure backup completion alerts
- **Storage Management**: Monitor backup size and disk usage

## Project Structure

```
IMAP-Backup-macOS/
├── Package.swift                 # Swift Package Manager configuration
├── Sources/
│   ├── main.swift               # App entry point
│   ├── App.swift                # SwiftUI App configuration
│   ├── Models/                  # Data models
│   │   ├── Account.swift        # Email account model
│   │   ├── AppState.swift       # Application state management
│   │   └── BackupProgress.swift # Backup progress tracking
│   ├── Services/                # Core services
│   │   ├── IMAPService.swift    # IMAP client implementation
│   │   ├── BackupService.swift  # Backup orchestration
│   │   └── KeychainService.swift # Secure password storage
│   └── Views/                   # SwiftUI views
│       ├── ContentView.swift    # Main app interface
│       ├── AccountListView.swift # Account management
│       ├── AddAccountView.swift # Account creation
│       ├── BackupView.swift     # Backup progress/status
│       └── SettingsView.swift   # App settings
├── IMAP Backup.app/            # Pre-built app bundle
└── Documentation/              # Additional documentation
```

## Dependencies

The app uses several Swift packages for functionality:

- **SwiftNIO + SwiftNIO-SSL**: Networking and SSL/TLS support
- **CryptoSwift**: Cryptographic operations
- **Swift Collections**: Enhanced data structures
- **Swift Log**: Logging framework

Dependencies are automatically managed by Swift Package Manager.

## Security & Privacy

- **Keychain Integration**: Passwords stored securely in macOS Keychain
- **App Sandbox**: Runs with limited system access for security
- **Network Security**: SSL/TLS encryption for all IMAP connections
- **No Data Collection**: Your email data stays on your device

## Troubleshooting

### Common Issues

**"Cannot connect to IMAP server"**
- Verify server address and port
- Check internet connection
- Ensure SSL/TLS settings match your provider
- Try disabling firewall temporarily

**"Authentication failed"**
- For Gmail: Use App Password instead of regular password
- For Outlook: Ensure account supports IMAP
- Verify credentials are correct

**"Permission denied" when selecting backup folder**
- Grant Full Disk Access in System Preferences → Security & Privacy
- Choose a folder in your home directory

### Getting Help

1. Check the [Issues](https://github.com/kzahedi/IMAP-Backup-macOS/issues) page
2. Search existing issues or create a new one
3. Include system information and error messages

## Contributing

We welcome contributions\! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by the original Go-based IMAP backup tool
- Built with Swift 6 and SwiftUI for modern macOS
- Uses SwiftNIO for high-performance networking

---

**Note**: This app is designed for personal email backup purposes. Please ensure you comply with your email provider's terms of service and any applicable data protection regulations.
EOF < /dev/null
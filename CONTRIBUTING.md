# Contributing to IMAP Backup for macOS

Thank you for your interest in contributing to IMAP Backup for macOS\! This document provides guidelines and information for contributors.

## Code of Conduct

By participating in this project, you agree to abide by our Code of Conduct:

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Respect different viewpoints and experiences

## Getting Started

### Development Environment

1. **macOS Requirements:**
   - macOS 15.0 (Sequoia) or later
   - Xcode 16.0 or later
   - Swift 6.0 or later

2. **Clone the Repository:**
   ```bash
   git clone https://github.com/kzahedi/IMAP-Backup-macOS.git
   cd IMAP-Backup-macOS
   ```

3. **Build the Project:**
   ```bash
   swift build
   ```

4. **Run Tests:**
   ```bash
   swift test
   ```

### Project Structure

- `Sources/` - Main source code
  - `Models/` - Data models and structures
  - `Services/` - Core business logic and services
  - `Views/` - SwiftUI views and UI components
- `Tests/` - Unit tests
- `Documentation/` - Additional documentation

## Development Guidelines

### Code Style

We follow standard Swift conventions:

- Use Swift 6 syntax and features
- Follow SwiftUI best practices
- Use `@MainActor` for UI-related code
- Implement proper error handling
- Add documentation comments for public APIs

### Example Code Style:

```swift
/// Service for managing IMAP connections and email backup operations
@MainActor
class IMAPService: ObservableObject {
    @Published var connectionStatus: ConnectionStatus = .disconnected
    
    /// Connects to the IMAP server with the provided credentials
    /// - Parameters:
    ///   - account: The email account to connect to
    /// - Returns: Success or failure result
    func connect(to account: Account) async -> Result<Void, IMAPError> {
        // Implementation
    }
}
```

### Commit Messages

Use clear, descriptive commit messages:

- Use present tense ("Add feature" not "Added feature")
- Keep the first line under 50 characters
- Reference issues and pull requests when applicable

Examples:
```
Add Gmail OAuth2 authentication support

Implement backup progress cancellation

Fix memory leak in IMAP connection handling

Update dependencies to latest versions
```

### Testing

- Write unit tests for new functionality
- Ensure all tests pass before submitting
- Test on multiple macOS versions when possible
- Include integration tests for IMAP functionality

## Contributing Process

### Before You Start

1. **Check existing issues** to see if your idea is already being discussed
2. **Open an issue** to discuss new features or significant changes
3. **Fork the repository** and create a feature branch

### Making Changes

1. **Create a branch** from `main`:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** following the guidelines above

3. **Test your changes** thoroughly:
   ```bash
   swift test
   swift build -c release
   ```

4. **Commit your changes**:
   ```bash
   git add .
   git commit -m "Add your descriptive commit message"
   ```

### Submitting Changes

1. **Push your branch**:
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create a Pull Request** with:
   - Clear description of changes
   - Link to related issues
   - Screenshots for UI changes
   - Test results

3. **Address review feedback** promptly

## Types of Contributions

### 🐛 Bug Reports

When reporting bugs, please include:

- macOS version and hardware
- App version or commit hash
- Steps to reproduce
- Expected vs actual behavior
- Console logs if applicable
- Screenshots if relevant

### 💡 Feature Requests

For new features:

- Describe the problem you're solving
- Explain your proposed solution
- Consider alternative approaches
- Discuss potential impact

### 📚 Documentation

- Fix typos and improve clarity
- Add missing documentation
- Update outdated information
- Improve code examples

### 🔧 Code Contributions

Priority areas for contributions:

- **IMAP Protocol Support**: Additional authentication methods, server compatibility
- **UI/UX Improvements**: Better user experience, accessibility features
- **Performance**: Optimize backup speed, memory usage
- **Error Handling**: Better error messages, recovery mechanisms
- **Testing**: Unit tests, integration tests, UI tests

## Architecture Guidelines

### SwiftUI Views

- Keep views focused and single-purpose
- Use `@StateObject` for view-owned objects
- Use `@EnvironmentObject` for shared state
- Extract reusable components

### Services

- Use actor isolation for thread safety
- Implement proper error handling
- Use dependency injection for testing
- Follow single responsibility principle

### Data Models

- Use `Codable` for persistence
- Implement proper equality and hashing
- Use value types when appropriate
- Add validation logic

## Security Considerations

When contributing:

- Never commit passwords or API keys
- Use Keychain for sensitive data storage
- Validate all user inputs
- Use secure communication protocols
- Follow macOS security guidelines

## Building and Testing

### Local Development

```bash
# Build in debug mode
swift build

# Build in release mode
swift build -c release

# Run tests
swift test

# Run with Xcode
open Package.swift
```

### Creating App Bundle

```bash
# After building
mkdir -p "IMAP Backup.app/Contents/MacOS"
cp ".build/release/IMAP-Backup-macOS" "IMAP Backup.app/Contents/MacOS/IMAP Backup"
```

## Release Process

1. Update version numbers in `Package.swift` and `Info.plist`
2. Update `CHANGELOG.md` with new features and fixes
3. Create a release tag
4. Build and test the release candidate
5. Create GitHub release with compiled app

## Getting Help

- **GitHub Issues**: For bugs and feature requests
- **GitHub Discussions**: For general questions and ideas
- **Code Review**: All contributions go through review

## Recognition

Contributors will be recognized in:

- `CONTRIBUTORS.md` file
- Release notes for significant contributions
- GitHub contributor statistics

Thank you for contributing to IMAP Backup for macOS\! 🚀
EOF < /dev/null
# SecureDesk

A production-ready macOS desktop application built with Swift and SwiftUI, demonstrating best practices for security, architecture, and testability.

![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
![License](https://img.shields.io/badge/license-MIT-blue.svg)

## 🎯 Overview

SecureDesk is a modern macOS application built with SwiftUI that showcases:
- **Protocol-oriented architecture** with dependency injection
- **Secure storage** using Keychain and CryptoKit
- **Mock data layer** for development (backend-ready)
- **Comprehensive testing** with XCTest and XCUITest
- **CI/CD automation** with GitHub Actions
- **Code signing and notarization** for distribution

## ✨ Features

- 🔐 **Secure Authentication** - Token-based auth with Keychain storage
- 📊 **Dashboard** - Item management with filtering and search
- ➕ **Create Items** - Full-featured form to create new items
- ✏️ **Edit Items** - Update item status inline
- 🗑️ **Delete Items** - Remove items with confirmation
- ⚙️ **Settings** - User profile and preferences
- 🎨 **Modern UI** - Native macOS design with SwiftUI
- 🧪 **Mock Mode** - Development mode with simulated backend
- 🔄 **Async/Await** - Modern Swift concurrency
- 🛡️ **Encryption** - AES-GCM encryption with CryptoKit
- ✅ **High Test Coverage** - Unit and UI tests

## 📋 Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later
- Swift 5.9 or later
- SwiftLint (optional, for linting)

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/SecureDesk.git
cd SecureDesk
```

### 2. Open in Xcode

```bash
open SecureDesk.xcodeproj
```

### 3. Install SwiftLint (Optional)

```bash
brew install swiftlint
```

### 4. Build and Run

1. Select the **SecureDesk** scheme
2. Choose your Mac as the destination
3. Press `Cmd+R` to build and run

## 🔑 Mock Credentials

The app runs in **mock mode** by default. You can log in with any of these credentials:

| Email | Password |
|-------|----------|
| `demo@securedesk.app` | `demo` |
| `john.doe@example.com` | `password123` |
| `jane.smith@example.com` | `password123` |
| Any email | Any password |

> **Note:** In mock mode, any non-empty email/password combination will work.

## 🏗️ Architecture

### Project Structure

```
SecureDesk/
├── App/
│   └── AppContainer.swift          # Dependency injection container
├── Models/
│   ├── User.swift                  # User model
│   ├── Item.swift                  # Item/task model
│   └── AuthToken.swift             # Authentication token
├── Views/
│   ├── Auth/                       # Login views
│   ├── Dashboard/                  # Dashboard views
│   ├── Settings/                   # Settings views
│   ├── Components/                 # Reusable components
│   └── Navigation/                 # Navigation structure
├── ViewModels/
│   ├── LoginViewModel.swift
│   ├── DashboardViewModel.swift
│   └── SettingsViewModel.swift
├── Services/
│   ├── Protocols/                  # Service protocols
│   ├── Mock/                       # Mock implementations
│   ├── Networking/                 # Network client
│   └── Storage/                    # Keychain & Encryption
└── Resources/
    ├── Config/
    │   └── FeatureFlags.swift      # Feature toggles
    └── Fixtures/                   # Mock JSON data
```

### Key Design Patterns

- **Protocol-Oriented Programming** - All services defined as protocols
- **Dependency Injection** - AppContainer manages service lifecycle
- **MVVM Architecture** - ViewModels handle business logic
- **Async/Await** - Modern concurrency throughout
- **Feature Flags** - Toggle mock vs. real services

## 🧪 Testing

### Run Unit Tests

```bash
# From command line
xcodebuild test \
  -project SecureDesk.xcodeproj \
  -scheme SecureDesk \
  -destination 'platform=macOS'

# Or press Cmd+U in Xcode
```

### Run UI Tests

```bash
xcodebuild test \
  -project SecureDesk.xcodeproj \
  -scheme SecureDeskUITests \
  -destination 'platform=macOS'
```

### Test Coverage

- **Unit Tests**: LoginViewModel, NetworkClient, Keychain, Encryption, Mock Services
- **UI Tests**: Login flow, Dashboard navigation, Settings, Error states

## ⚙️ Configuration

### Feature Flags

Toggle features in `FeatureFlags.swift`:

```swift
// Use mock services instead of real API
static var useMockServices: Bool { ... }

// Enable verbose logging
static var enableVerboseLogging: Bool { ... }

// Enable network request logging
static var logNetworkRequests: Bool { ... }

// API base URL
static var apiBaseURL: URL { ... }
```

### Environment Variables

Set environment variables to override defaults:

```bash
# Use mock services
USE_MOCK_SERVICES=true

# API base URL
API_BASE_URL=https://api.yourdomain.com
```

## 🔐 Security

### Secure Storage

- **Keychain** - Authentication tokens stored securely in macOS Keychain
- **CryptoKit** - AES-GCM encryption for sensitive data
- **No Plain Text** - Passwords never stored, only hashed tokens

### Sandboxing

The app is sandboxed for security:
- Limited file system access
- Network access only when needed
- Keychain access for secure storage

## 🚢 Distribution

### Code Signing & Notarization

Build, sign, and notarize the app for distribution:

```bash
# Set up credentials first (one-time setup)
xcrun notarytool store-credentials "SecureDesk-Notarize" \
    --apple-id "your-apple-id@example.com" \
    --team-id "YOUR_TEAM_ID" \
    --password "app-specific-password"

# Build and notarize
./scripts/notarize.sh
```

The script will:
1. Build and archive the app
2. Export with Developer ID
3. Create a DMG
4. Sign and notarize
5. Staple the notarization ticket

Output: `build/SecureDesk.dmg`

## 🤖 CI/CD

### GitHub Actions

The project includes a complete CI/CD pipeline:

- **Linting** - SwiftLint checks on every push
- **Build** - Automated builds for main/develop
- **Unit Tests** - Run on every PR
- **UI Tests** - Automated UI testing
- **Code Coverage** - Coverage reports on PRs

Workflow file: `.github/workflows/ci.yml`

## 🔧 Development

### Linting

Run SwiftLint:

```bash
swiftlint lint
```

Auto-fix issues:

```bash
swiftlint --fix
```

### Code Style

The project follows:
- Swift API Design Guidelines
- SwiftLint rules (see `.swiftlint.yml`)
- Protocol-oriented design principles
- SOLID principles

## 🌐 Backend Integration

### Switching from Mock to Real API

1. **Implement Real Services**:
   ```swift
   // Create RealAuthService.swift conforming to AuthServiceProtocol
   final class RealAuthService: AuthServiceProtocol {
       private let networkClient: NetworkClient
       
       func login(email: String, password: String) async throws -> AuthToken {
           // Use networkClient to call real API
       }
   }
   ```

2. **Update AppContainer**:
   ```swift
   var authService: any AuthServiceProtocol {
       if FeatureFlags.useMockServices {
           return MockAuthService(keychainService: keychainService)
       } else {
           return RealAuthService(networkClient: networkClient)
       }
   }
   ```

3. **Configure API URL**:
   ```swift
   // In FeatureFlags.swift or environment variable
   static var apiBaseURL: URL {
       return URL(string: "https://api.yourdomain.com")!
   }
   ```

4. **Toggle Feature Flag**:
   ```swift
   // Set to false to use real services
   static var useMockServices: Bool { false }
   ```

## 📚 Documentation

- [Architecture Guide](docs/ARCHITECTURE.md) _(coming soon)_
- [API Documentation](docs/API.md) _(coming soon)_
- [Contributing Guidelines](CONTRIBUTING.md) _(coming soon)_
- [Changelog](CHANGELOG.md) _(coming soon)_

## 🐛 Troubleshooting

### Build Errors

**"Command SwiftLint not found"**
```bash
brew install swiftlint
```

**Signing Issues**
- Ensure you have a valid Developer ID certificate
- Check code signing settings in Xcode

### Runtime Issues

**"App cannot be opened"**
- Run notarization script
- Check Gatekeeper settings: System Preferences > Security & Privacy

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- **Vipin Saini** - Initial work

## 🙏 Acknowledgments

- Built with Swift and SwiftUI
- Icons from SF Symbols
- Mock data generated with care

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/SecureDesk/issues)
- **Email**: support@securedesk.app
- **Documentation**: [GitHub Wiki](https://github.com/yourusername/SecureDesk/wiki)

---

**Made with ❤️ using Swift and SwiftUI**

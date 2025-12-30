//
//  FeatureFlag.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation

/// All available feature flags in the application
/// Use these to toggle functionality without code changes
enum FeatureFlag: String, CaseIterable, Identifiable, Sendable {
    
    // MARK: - Core Features
    
    /// Enable offline mode with local caching
    case enableOfflineMode
    
    /// Enable advanced search with fuzzy matching
    case enableAdvancedSearch
    
    // MARK: - Security Features
    
    /// Enable biometric authentication (Touch ID/Face ID)
    case enableBiometricAuth
    
    /// Enable auto-lock after inactivity
    case enableAutoLock
    
    // MARK: - Developer Features
    
    /// Show debug menu in app (DEBUG builds only)
    case enableDebugMenu
    
    /// Enable chaos testing mode (DEBUG builds only)
    case enableChaosMode
    
    /// Enable verbose logging
    case enableVerboseLogging
    
    /// Enable network request logging
    case enableNetworkLogging
    
    // MARK: - Experimental Features
    
    /// Enable new dashboard UI
    case enableNewDashboard
    
    /// Enable keyboard shortcuts
    case enableKeyboardShortcuts
    
    // MARK: - Properties
    
    var id: String { rawValue }
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .enableOfflineMode: return "Offline Mode"
        case .enableAdvancedSearch: return "Advanced Search"
        case .enableBiometricAuth: return "Biometric Authentication"
        case .enableAutoLock: return "Auto-Lock"
        case .enableDebugMenu: return "Debug Menu"
        case .enableChaosMode: return "Chaos Testing"
        case .enableVerboseLogging: return "Verbose Logging"
        case .enableNetworkLogging: return "Network Logging"
        case .enableNewDashboard: return "New Dashboard"
        case .enableKeyboardShortcuts: return "Keyboard Shortcuts"
        }
    }
    
    /// Description of what the flag does
    var description: String {
        switch self {
        case .enableOfflineMode:
            return "App works fully offline with cached data"
        case .enableAdvancedSearch:
            return "Full-text search with fuzzy matching and filters"
        case .enableBiometricAuth:
            return "Use Touch ID or Face ID to unlock"
        case .enableAutoLock:
            return "Lock app after period of inactivity"
        case .enableDebugMenu:
            return "Show developer debug tools"
        case .enableChaosMode:
            return "Simulate failures for testing"
        case .enableVerboseLogging:
            return "Log detailed debug information"
        case .enableNetworkLogging:
            return "Log all network requests and responses"
        case .enableNewDashboard:
            return "Use the redesigned dashboard UI"
        case .enableKeyboardShortcuts:
            return "Enable keyboard shortcuts for common actions"
        }
    }
    
    /// Default value when flag hasn't been set
    var defaultValue: Bool {
        switch self {
        case .enableOfflineMode: return true
        case .enableAdvancedSearch: return true
        case .enableBiometricAuth: return false
        case .enableAutoLock: return false
        case .enableDebugMenu: return isDebugBuild
        case .enableChaosMode: return false
        case .enableVerboseLogging: return isDebugBuild
        case .enableNetworkLogging: return isDebugBuild
        case .enableNewDashboard: return false
        case .enableKeyboardShortcuts: return true
        }
    }
    
    /// Whether this flag should only be available in DEBUG builds
    var isDebugOnly: Bool {
        switch self {
        case .enableDebugMenu, .enableChaosMode, .enableVerboseLogging, .enableNetworkLogging:
            return true
        default:
            return false
        }
    }
    
    /// Category for grouping in UI
    var category: FeatureFlagCategory {
        switch self {
        case .enableOfflineMode, .enableAdvancedSearch, .enableKeyboardShortcuts:
            return .core
        case .enableBiometricAuth, .enableAutoLock:
            return .security
        case .enableDebugMenu, .enableChaosMode, .enableVerboseLogging, .enableNetworkLogging:
            return .developer
        case .enableNewDashboard:
            return .experimental
        }
    }
    
    /// Key used for UserDefaults storage
    var storageKey: String {
        "featureFlag_\(rawValue)"
    }
    
    // MARK: - Private Helpers
    
    private var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
}

// MARK: - Feature Flag Category

enum FeatureFlagCategory: String, CaseIterable, Identifiable {
    case core = "Core Features"
    case security = "Security"
    case developer = "Developer"
    case experimental = "Experimental"
    
    var id: String { rawValue }
    
    var flags: [FeatureFlag] {
        FeatureFlag.allCases.filter { $0.category == self }
    }
}

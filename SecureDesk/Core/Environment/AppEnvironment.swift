//
//  AppEnvironment.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation

/// Application environment configuration
/// Determines which backend/services to connect to
enum AppEnvironment: String, CaseIterable, Identifiable, Sendable {
    case mock
    case staging
    case production
    
    var id: String { rawValue }
    
    // MARK: - Display Properties
    
    var displayName: String {
        switch self {
        case .mock: return "Mock"
        case .staging: return "Staging"
        case .production: return "Production"
        }
    }
    
    var description: String {
        switch self {
        case .mock: return "Local mock data, no network"
        case .staging: return "Staging server for testing"
        case .production: return "Production server"
        }
    }
    
    var icon: String {
        switch self {
        case .mock: return "doc.text"
        case .staging: return "hammer"
        case .production: return "globe"
        }
    }
    
    var color: String {
        switch self {
        case .mock: return "orange"
        case .staging: return "yellow"
        case .production: return "green"
        }
    }
    
    // MARK: - Configuration
    
    /// Base URL for API requests
    var baseURL: URL {
        switch self {
        case .mock:
            // Mock doesn't need a real URL
            return URL(string: "https://mock.securedesk.local")!
        case .staging:
            return URL(string: "https://staging-api.securedesk.app")!
        case .production:
            return URL(string: "https://api.securedesk.app")!
        }
    }
    
    /// Whether to use mock services
    var useMockServices: Bool {
        switch self {
        case .mock: return true
        case .staging, .production: return false
        }
    }
    
    /// Whether this environment requires authentication
    var requiresAuth: Bool {
        switch self {
        case .mock: return false // Mock accepts any credentials
        case .staging, .production: return true
        }
    }
    
    /// Request timeout interval in seconds
    var requestTimeout: TimeInterval {
        switch self {
        case .mock: return 5
        case .staging: return 30
        case .production: return 15
        }
    }
    
    /// Whether verbose logging should be enabled
    var enableLogging: Bool {
        switch self {
        case .mock, .staging: return true
        case .production: return false
        }
    }
    
    /// Whether this is a debug-only environment
    var isDebugOnly: Bool {
        switch self {
        case .mock, .staging: return true
        case .production: return false
        }
    }
    
    // MARK: - Feature Overrides
    
    /// Environment-specific feature overrides
    var featureOverrides: [FeatureFlag: Bool] {
        switch self {
        case .mock:
            return [
                .enableVerboseLogging: true,
                .enableDebugMenu: true
            ]
        case .staging:
            return [
                .enableVerboseLogging: true
            ]
        case .production:
            return [
                .enableDebugMenu: false,
                .enableChaosMode: false,
                .enableVerboseLogging: false
            ]
        }
    }
    
    // MARK: - Storage
    
    private static let storageKey = "app_environment"
    
    /// Get the stored environment or default
    static var stored: AppEnvironment {
        guard let rawValue = UserDefaults.standard.string(forKey: storageKey),
              let env = AppEnvironment(rawValue: rawValue) else {
            return defaultEnvironment
        }
        return env
    }
    
    /// Save environment to storage
    func save() {
        UserDefaults.standard.set(rawValue, forKey: Self.storageKey)
    }
    
    /// Default environment based on build configuration
    static var defaultEnvironment: AppEnvironment {
        #if DEBUG
        return .mock
        #else
        return .production
        #endif
    }
}

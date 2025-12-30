//
//  FeatureFlags.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation

/// Feature flags for controlling app behavior
/// Use these to toggle between mock and real implementations
enum FeatureFlags {
    
    // MARK: - Environment Detection
    
    /// Returns true if running in DEBUG configuration
    static var isDebug: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// Returns true if running in Xcode previews
    static var isPreview: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    /// Returns true if running unit tests
    static var isTesting: Bool {
        NSClassFromString("XCTestCase") != nil
    }
    
    // MARK: - Service Flags
    
    /// Use mock services instead of real API
    /// - In DEBUG: defaults to true
    /// - In RELEASE: defaults to false
    /// - Can be overridden via UserDefaults or environment variable
    static var useMockServices: Bool {
        // Check environment variable first
        if let envValue = ProcessInfo.processInfo.environment["USE_MOCK_SERVICES"] {
            return envValue.lowercased() == "true" || envValue == "1"
        }
        
        // Check UserDefaults for runtime override
        if UserDefaults.standard.object(forKey: "useMockServices") != nil {
            return UserDefaults.standard.bool(forKey: "useMockServices")
        }
        
        // Default based on configuration
        return isDebug || isPreview || isTesting
    }
    
    /// Enable verbose logging
    static var enableVerboseLogging: Bool {
        isDebug
    }
    
    /// Enable network request logging
    static var logNetworkRequests: Bool {
        isDebug
    }
    
    // MARK: - Feature Toggles
    
    /// Enable offline mode support
    static var enableOfflineMode: Bool = true
    
    /// Enable local caching
    static var enableCaching: Bool = true
    
    /// Simulated network delay for mock services (seconds)
    static var mockNetworkDelay: Double = 0.5
    
    // MARK: - API Configuration
    
    /// Base URL for the API
    static var apiBaseURL: URL {
        if useMockServices {
            // Mock services don't need a real URL
            // swiftlint:disable:next force_unwrapping
            return URL(string: "https://mock.securedesk.local")!
        }
        
        // Production API URL
        if let urlString = ProcessInfo.processInfo.environment["API_BASE_URL"],
           let url = URL(string: urlString) {
            return url
        }
        
        // Default production URL
        // swiftlint:disable:next force_unwrapping
        return URL(string: "https://api.securedesk.app")!
    }
}

// MARK: - Debug Helpers

#if DEBUG
extension FeatureFlags {
    /// Toggle mock services at runtime (DEBUG only)
    static func setUseMockServices(_ value: Bool) {
        UserDefaults.standard.set(value, forKey: "useMockServices")
    }
    
    /// Reset all feature flags to defaults
    static func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: "useMockServices")
    }
}
#endif

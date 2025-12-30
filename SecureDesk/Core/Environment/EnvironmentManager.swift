//
//  EnvironmentManager.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation
import SwiftUI

/// Manages the current application environment
/// Handles switching, persistence, and service configuration
@MainActor
@Observable
final class EnvironmentManager {
    
    // MARK: - Singleton
    
    static let shared = EnvironmentManager()
    
    // MARK: - Properties
    
    /// Current active environment
    private(set) var current: AppEnvironment
    
    /// Whether environment can be changed (DEBUG only)
    var canChangeEnvironment: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }
    
    /// All available environments for the current build
    var availableEnvironments: [AppEnvironment] {
        #if DEBUG
        return AppEnvironment.allCases
        #else
        return AppEnvironment.allCases.filter { !$0.isDebugOnly }
        #endif
    }
    
    // MARK: - Computed Properties
    
    /// Base URL for the current environment
    var baseURL: URL { current.baseURL }
    
    /// Whether mock services should be used
    var useMockServices: Bool { current.useMockServices }
    
    /// Request timeout for current environment
    var requestTimeout: TimeInterval { current.requestTimeout }
    
    /// Whether logging is enabled
    var loggingEnabled: Bool { current.enableLogging }
    
    // MARK: - Initialization
    
    private init() {
        self.current = AppEnvironment.stored
        logEnvironment()
    }
    
    // MARK: - Public Methods
    
    /// Switch to a different environment
    /// - Parameter environment: The target environment
    /// - Returns: Whether the switch was successful
    @discardableResult
    func switchTo(_ environment: AppEnvironment) -> Bool {
        #if DEBUG
        performSwitch(to: environment)
        return true
        #else
        // Only allow switching to non-debug environments in release
        guard !environment.isDebugOnly else { return false }
        performSwitch(to: environment)
        return true
        #endif
    }
    
    /// Reset to default environment
    func resetToDefault() {
        switchTo(.defaultEnvironment)
    }
    
    /// Apply environment-specific feature flag overrides
    func applyFeatureOverrides(to flagManager: FeatureFlagManager) {
        for (flag, value) in current.featureOverrides {
            flagManager.setEnabled(flag, enabled: value)
        }
    }
    
    // MARK: - Private Methods
    
    private func performSwitch(to environment: AppEnvironment) {
        let previous = current
        current = environment
        environment.save()
        
        // Post notification for listeners
        NotificationCenter.default.post(
            name: .environmentDidChange,
            object: environment,
            userInfo: ["previous": previous]
        )
        
        logEnvironmentChange(from: previous, to: environment)
    }
    
    private func logEnvironment() {
        #if DEBUG
        print("[Environment] Current: \(current.displayName)")
        print("[Environment] Base URL: \(current.baseURL)")
        print("[Environment] Mock Services: \(current.useMockServices)")
        #endif
    }
    
    private func logEnvironmentChange(from: AppEnvironment, to: AppEnvironment) {
        #if DEBUG
        print("[Environment] Switched: \(from.displayName) → \(to.displayName)")
        #endif
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let environmentDidChange = Notification.Name("environmentDidChange")
}

// MARK: - SwiftUI Environment

private struct EnvironmentManagerKey: EnvironmentKey {
    @MainActor static let defaultValue = EnvironmentManager.shared
}

extension EnvironmentValues {
    var environmentManager: EnvironmentManager {
        get { self[EnvironmentManagerKey.self] }
        set { self[EnvironmentManagerKey.self] = newValue }
    }
}

// MARK: - Environment Badge View

/// Badge showing current environment (for DEBUG builds)
struct EnvironmentBadge: View {
    @Environment(\.environmentManager) private var manager
    
    var body: some View {
        #if DEBUG
        if manager.current != .production {
            Text(manager.current.displayName.uppercased())
                .font(.caption2)
                .fontWeight(.bold)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(badgeColor, in: Capsule())
                .foregroundStyle(.white)
        }
        #endif
    }
    
    private var badgeColor: Color {
        switch manager.current {
        case .mock: return .orange
        case .staging: return .yellow
        case .production: return .green
        }
    }
}

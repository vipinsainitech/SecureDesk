//
//  FeatureFlagManager.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation
import Combine

/// Centralized manager for feature flags
/// Handles persistence, runtime toggling, and observation
@MainActor
@Observable
final class FeatureFlagManager {
    
    // MARK: - Singleton
    
    static let shared = FeatureFlagManager()
    
    // MARK: - Properties
    
    private let userDefaults: UserDefaults
    private let notificationCenter: NotificationCenter
    
    /// Cache of flag values for performance
    private var flagCache: [FeatureFlag: Bool] = [:]
    
    // MARK: - Initialization
    
    init(
        userDefaults: UserDefaults = .standard,
        notificationCenter: NotificationCenter = .default
    ) {
        self.userDefaults = userDefaults
        self.notificationCenter = notificationCenter
        loadAllFlags()
    }
    
    // MARK: - Public API
    
    /// Check if a feature flag is enabled
    /// - Parameter flag: The feature flag to check
    /// - Returns: Whether the flag is enabled
    func isEnabled(_ flag: FeatureFlag) -> Bool {
        // Debug-only flags are disabled in release builds
        #if !DEBUG
        if flag.isDebugOnly {
            return false
        }
        #endif
        
        // Return cached value or default
        return flagCache[flag] ?? flag.defaultValue
    }
    
    /// Enable or disable a feature flag
    /// - Parameters:
    ///   - flag: The feature flag to modify
    ///   - enabled: Whether to enable the flag
    func setEnabled(_ flag: FeatureFlag, enabled: Bool) {
        #if DEBUG
        // Allow all changes in debug
        performFlagUpdate(flag, enabled: enabled)
        #else
        // Only allow non-debug flags in release
        guard !flag.isDebugOnly else { return }
        performFlagUpdate(flag, enabled: enabled)
        #endif
    }
    
    /// Toggle a feature flag
    /// - Parameter flag: The feature flag to toggle
    func toggle(_ flag: FeatureFlag) {
        setEnabled(flag, enabled: !isEnabled(flag))
    }
    
    /// Reset a flag to its default value
    /// - Parameter flag: The feature flag to reset
    func resetToDefault(_ flag: FeatureFlag) {
        userDefaults.removeObject(forKey: flag.storageKey)
        flagCache[flag] = flag.defaultValue
        notifyFlagChanged(flag)
    }
    
    /// Reset all flags to their default values
    func resetAllToDefaults() {
        for flag in FeatureFlag.allCases {
            userDefaults.removeObject(forKey: flag.storageKey)
            flagCache[flag] = flag.defaultValue
        }
        notifyAllFlagsChanged()
    }
    
    /// Get all flags in a specific category
    /// - Parameter category: The category to filter by
    /// - Returns: Dictionary of flags and their current values
    func flags(in category: FeatureFlagCategory) -> [(flag: FeatureFlag, enabled: Bool)] {
        category.flags.map { ($0, isEnabled($0)) }
    }
    
    /// Get all available flags (respecting debug-only in release)
    var availableFlags: [FeatureFlag] {
        #if DEBUG
        return FeatureFlag.allCases
        #else
        return FeatureFlag.allCases.filter { !$0.isDebugOnly }
        #endif
    }
    
    // MARK: - Private Methods
    
    private func loadAllFlags() {
        for flag in FeatureFlag.allCases {
            if userDefaults.object(forKey: flag.storageKey) != nil {
                flagCache[flag] = userDefaults.bool(forKey: flag.storageKey)
            } else {
                flagCache[flag] = flag.defaultValue
            }
        }
    }
    
    private func performFlagUpdate(_ flag: FeatureFlag, enabled: Bool) {
        let previousValue = flagCache[flag]
        guard previousValue != enabled else { return }
        
        flagCache[flag] = enabled
        userDefaults.set(enabled, forKey: flag.storageKey)
        notifyFlagChanged(flag)
        
        logFlagChange(flag, from: previousValue ?? flag.defaultValue, to: enabled)
    }
    
    private func notifyFlagChanged(_ flag: FeatureFlag) {
        notificationCenter.post(
            name: .featureFlagDidChange,
            object: flag
        )
    }
    
    private func notifyAllFlagsChanged() {
        notificationCenter.post(
            name: .featureFlagsDidReset,
            object: nil
        )
    }
    
    private func logFlagChange(_ flag: FeatureFlag, from: Bool, to: Bool) {
        #if DEBUG
        print("[FeatureFlags] \(flag.displayName): \(from) → \(to)")
        #endif
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let featureFlagDidChange = Notification.Name("featureFlagDidChange")
    static let featureFlagsDidReset = Notification.Name("featureFlagsDidReset")
}

// MARK: - Convenience Extensions

extension FeatureFlagManager {
    
    /// Quick access to common flags
    var isOfflineModeEnabled: Bool { isEnabled(.enableOfflineMode) }
    var isAdvancedSearchEnabled: Bool { isEnabled(.enableAdvancedSearch) }
    var isDebugMenuEnabled: Bool { isEnabled(.enableDebugMenu) }
    var isChaosModeEnabled: Bool { isEnabled(.enableChaosMode) }
    var isVerboseLoggingEnabled: Bool { isEnabled(.enableVerboseLogging) }
}

// MARK: - SwiftUI Environment

import SwiftUI

private struct FeatureFlagManagerKey: EnvironmentKey {
    @MainActor static let defaultValue = FeatureFlagManager.shared
}

extension EnvironmentValues {
    var featureFlags: FeatureFlagManager {
        get { self[FeatureFlagManagerKey.self] }
        set { self[FeatureFlagManagerKey.self] = newValue }
    }
}

// MARK: - Property Wrapper (Optional)

/// Property wrapper for convenient feature flag access in views
@propertyWrapper
struct FeatureFlagValue: DynamicProperty {
    private let flag: FeatureFlag
    @Environment(\.featureFlags) private var manager
    
    init(_ flag: FeatureFlag) {
        self.flag = flag
    }
    
    var wrappedValue: Bool {
        manager.isEnabled(flag)
    }
}

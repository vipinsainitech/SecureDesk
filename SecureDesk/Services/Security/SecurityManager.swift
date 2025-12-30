//
//  SecurityManager.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation
import SwiftUI

/// Manages security features including auto-lock and token lifecycle
@MainActor
@Observable
final class SecurityManager {
    
    // MARK: - Singleton
    
    static let shared = SecurityManager()
    
    // MARK: - Properties
    
    /// Whether the app is currently locked
    private(set) var isLocked: Bool = false
    
    /// Last activity timestamp
    private(set) var lastActivityTime: Date = Date()
    
    /// Auto-lock timeout in seconds (default: 5 minutes)
    var autoLockTimeout: TimeInterval = 300
    
    /// Whether biometric auth is available
    private(set) var isBiometricAvailable: Bool = false
    
    /// Current biometric type (if available)
    private(set) var biometricType: BiometricType = .none
    
    // MARK: - Private Properties
    
    private var activityTimer: Timer?
    private let notificationCenter: NotificationCenter
    
    // MARK: - Initialization
    
    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        checkBiometricCapabilities()
        setupActivityMonitoring()
    }
    
    // MARK: - Public Methods
    
    /// Record user activity (resets auto-lock timer)
    func recordActivity() {
        lastActivityTime = Date()
        
        if isLocked {
            // Don't reset timer while locked
            return
        }
        
        restartAutoLockTimer()
    }
    
    /// Lock the app
    func lock() {
        guard !isLocked else { return }
        
        isLocked = true
        stopAutoLockTimer()
        
        notificationCenter.post(name: .appDidLock, object: nil)
        logSecurity("App locked")
    }
    
    /// Unlock the app (with optional biometric)
    /// - Parameter useBiometric: Whether to use biometric authentication
    /// - Returns: Whether unlock was successful
    func unlock(useBiometric: Bool = false) async -> Bool {
        if useBiometric && isBiometricAvailable {
            let authenticated = await authenticateWithBiometric()
            if authenticated {
                performUnlock()
                return true
            }
            return false
        }
        
        // Mock unlock for now
        performUnlock()
        return true
    }
    
    /// Simulate token expiration (for testing)
    func simulateTokenExpiration() {
        notificationCenter.post(name: .tokenDidExpire, object: nil)
        logSecurity("Token expired (simulated)")
    }
    
    /// Check if auto-lock should trigger
    func checkAutoLock() {
        guard FeatureFlagManager.shared.isEnabled(.enableAutoLock) else { return }
        guard !isLocked else { return }
        
        let timeSinceActivity = Date().timeIntervalSince(lastActivityTime)
        if timeSinceActivity >= autoLockTimeout {
            lock()
        }
    }
    
    // MARK: - Private Methods
    
    private func performUnlock() {
        isLocked = false
        lastActivityTime = Date()
        restartAutoLockTimer()
        
        notificationCenter.post(name: .appDidUnlock, object: nil)
        logSecurity("App unlocked")
    }
    
    private func checkBiometricCapabilities() {
        // Mock biometric check
        // In real app, use LAContext to check
        #if targetEnvironment(simulator)
        isBiometricAvailable = false
        biometricType = .none
        #else
        // Would check using LocalAuthentication framework
        isBiometricAvailable = true
        biometricType = .touchID
        #endif
    }
    
    private func authenticateWithBiometric() async -> Bool {
        // Mock biometric authentication
        // In real app, use LAContext.evaluatePolicy
        
        logSecurity("Biometric authentication requested")
        
        // Simulate delay
        try? await Task.sleep(for: .milliseconds(500))
        
        // Always succeed in mock
        return true
    }
    
    private func setupActivityMonitoring() {
        // Monitor system events for idle detection
        notificationCenter.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.recordActivity()
        }
        
        notificationCenter.addObserver(
            forName: NSApplication.didResignActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Start checking for auto-lock when app becomes inactive
            self?.checkAutoLock()
        }
    }
    
    private func restartAutoLockTimer() {
        stopAutoLockTimer()
        
        guard FeatureFlagManager.shared.isEnabled(.enableAutoLock) else { return }
        
        activityTimer = Timer.scheduledTimer(
            withTimeInterval: autoLockTimeout,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor in
                self?.checkAutoLock()
            }
        }
    }
    
    private func stopAutoLockTimer() {
        activityTimer?.invalidate()
        activityTimer = nil
    }
    
    private func logSecurity(_ message: String) {
        #if DEBUG
        if FeatureFlagManager.shared.isVerboseLoggingEnabled {
            print("[Security] \(message)")
        }
        #endif
    }
}

// MARK: - Biometric Type

enum BiometricType: String, Sendable {
    case none
    case touchID
    case faceID
    
    var displayName: String {
        switch self {
        case .none: return "None"
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        }
    }
    
    var icon: String {
        switch self {
        case .none: return "lock"
        case .touchID: return "touchid"
        case .faceID: return "faceid"
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let appDidLock = Notification.Name("appDidLock")
    static let appDidUnlock = Notification.Name("appDidUnlock")
    static let tokenDidExpire = Notification.Name("tokenDidExpire")
}

// MARK: - SwiftUI Environment

private struct SecurityManagerKey: EnvironmentKey {
    @MainActor static let defaultValue = SecurityManager.shared
}

extension EnvironmentValues {
    var securityManager: SecurityManager {
        get { self[SecurityManagerKey.self] }
        set { self[SecurityManagerKey.self] = newValue }
    }
}

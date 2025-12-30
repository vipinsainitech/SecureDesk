//
//  AppStateManager.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation
import SwiftUI
import Combine

/// Manages the global application state
/// Coordinates state transitions and notifies observers
@MainActor
@Observable
final class AppStateManager {
    
    // MARK: - Singleton
    
    static let shared = AppStateManager()
    
    // MARK: - Properties
    
    /// Current application state
    private(set) var currentState: AppState = .launching
    
    /// Previous state for rollback
    private var previousState: AppState?
    
    /// State history for debugging
    private var stateHistory: [StateTransition] = []
    private let maxHistorySize = 50
    
    // MARK: - Dependencies
    
    private let networkMonitor: NetworkMonitor
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(networkMonitor: NetworkMonitor = .shared) {
        self.networkMonitor = networkMonitor
        setupNetworkMonitoring()
    }
    
    // MARK: - State Transitions
    
    /// Transition to a new state
    /// - Parameter newState: The target state
    func transition(to newState: AppState) {
        guard canTransition(from: currentState, to: newState) else {
            logInvalidTransition(from: currentState, to: newState)
            return
        }
        
        performTransition(to: newState)
    }
    
    /// Transition to authenticated state
    func authenticate(user: User) {
        transition(to: .authenticated(user))
    }
    
    /// Transition to unauthenticated state
    func logout() {
        transition(to: .unauthenticated)
    }
    
    /// Lock the app
    func lock() {
        guard let user = currentState.currentUser else { return }
        transition(to: .locked(user))
    }
    
    /// Unlock the app
    func unlock() {
        guard case .locked(let user) = currentState else { return }
        transition(to: .authenticated(user))
    }
    
    /// Enter offline mode
    func enterOfflineMode() {
        let snapshot = AppStateSnapshot(from: currentState)
        transition(to: .offline(previousState: snapshot))
    }
    
    /// Exit offline mode and restore previous state
    func exitOfflineMode() {
        guard case .offline(let snapshot) = currentState else { return }
        
        if let user = snapshot.user, snapshot.wasAuthenticated {
            transition(to: .authenticated(user))
        } else {
            transition(to: .unauthenticated)
        }
    }
    
    /// Set error state
    func setError(_ error: AppStateError) {
        previousState = currentState
        transition(to: .error(error))
    }
    
    /// Recover from error state
    func recoverFromError() {
        guard case .error = currentState,
              let previous = previousState else { return }
        transition(to: previous)
    }
    
    /// Start syncing
    func startSync() {
        transition(to: .syncing(progress: 0))
    }
    
    /// Update sync progress
    func updateSyncProgress(_ progress: Double) {
        transition(to: .syncing(progress: min(1, max(0, progress))))
    }
    
    /// Complete syncing
    func completeSync() {
        guard let user = currentState.currentUser else {
            transition(to: .unauthenticated)
            return
        }
        transition(to: .authenticated(user))
    }
    
    // MARK: - Validation
    
    /// Check if a transition is valid
    private func canTransition(from: AppState, to: AppState) -> Bool {
        switch (from, to) {
        case (.launching, _):
            return true // Can transition from launching to any state
            
        case (.unauthenticated, .authenticated),
             (.unauthenticated, .error):
            return true
            
        case (.authenticated, .unauthenticated),
             (.authenticated, .locked),
             (.authenticated, .offline),
             (.authenticated, .error),
             (.authenticated, .syncing):
            return true
            
        case (.locked, .authenticated),
             (.locked, .unauthenticated):
            return true
            
        case (.offline, .authenticated),
             (.offline, .unauthenticated),
             (.offline, .error):
            return true
            
        case (.error, _):
            return true // Can recover to any state
            
        case (.syncing, .authenticated),
             (.syncing, .error),
             (.syncing, .syncing):
            return true
            
        default:
            return false
        }
    }
    
    // MARK: - Private Methods
    
    private func performTransition(to newState: AppState) {
        let transition = StateTransition(
            from: currentState,
            to: newState,
            timestamp: Date()
        )
        
        previousState = currentState
        currentState = newState
        
        recordTransition(transition)
        notifyStateChange()
        logTransition(transition)
    }
    
    private func recordTransition(_ transition: StateTransition) {
        stateHistory.append(transition)
        if stateHistory.count > maxHistorySize {
            stateHistory.removeFirst()
        }
    }
    
    private func notifyStateChange() {
        NotificationCenter.default.post(
            name: .appStateDidChange,
            object: currentState
        )
    }
    
    private func setupNetworkMonitoring() {
        NotificationCenter.default.addObserver(
            forName: .networkStatusDidChange,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let self = self else { return }
            
            let isConnected = notification.userInfo?["isConnected"] as? Bool ?? false
            
            Task { @MainActor in
                if !isConnected && self.currentState.isAuthenticated {
                    self.enterOfflineMode()
                } else if isConnected, case .offline = self.currentState {
                    self.exitOfflineMode()
                }
            }
        }
    }
    
    private func logTransition(_ transition: StateTransition) {
        #if DEBUG
        if FeatureFlagManager.shared.isVerboseLoggingEnabled {
            print("[AppState] \(transition.from.displayName) → \(transition.to.displayName)")
        }
        #endif
    }
    
    private func logInvalidTransition(from: AppState, to: AppState) {
        #if DEBUG
        print("[AppState] Invalid transition: \(from.displayName) → \(to.displayName)")
        #endif
    }
}

// MARK: - State Transition

private struct StateTransition {
    let from: AppState
    let to: AppState
    let timestamp: Date
}

// MARK: - Notification Names

extension Notification.Name {
    static let appStateDidChange = Notification.Name("appStateDidChange")
}

// MARK: - SwiftUI Environment

private struct AppStateManagerKey: EnvironmentKey {
    @MainActor static let defaultValue = AppStateManager.shared
}

extension EnvironmentValues {
    var appStateManager: AppStateManager {
        get { self[AppStateManagerKey.self] }
        set { self[AppStateManagerKey.self] = newValue }
    }
}

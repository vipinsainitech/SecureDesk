//
//  AppState.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation

/// Represents the overall application state
/// Used for coordinating UI and business logic
enum AppState: Equatable, Sendable {
    
    /// App is launching, performing initial setup
    case launching
    
    /// User is authenticated and app is ready
    case authenticated(User)
    
    /// User is not authenticated
    case unauthenticated
    
    /// App is in offline mode
    case offline(previousState: AppStateSnapshot)
    
    /// App is locked (requires re-authentication)
    case locked(User)
    
    /// App encountered an error
    case error(AppStateError)
    
    /// App is syncing data
    case syncing(progress: Double)
}

// MARK: - State Properties

extension AppState {
    
    /// Whether user is currently authenticated
    var isAuthenticated: Bool {
        switch self {
        case .authenticated, .locked, .syncing:
            return true
        case .offline(let snapshot):
            return snapshot.wasAuthenticated
        default:
            return false
        }
    }
    
    /// Whether the app is usable (can show main content)
    var isUsable: Bool {
        switch self {
        case .authenticated, .offline, .syncing:
            return true
        default:
            return false
        }
    }
    
    /// Whether the app is in a transitional state
    var isTransitional: Bool {
        switch self {
        case .launching, .syncing:
            return true
        default:
            return false
        }
    }
    
    /// Current user if available
    var currentUser: User? {
        switch self {
        case .authenticated(let user), .locked(let user):
            return user
        case .offline(let snapshot):
            return snapshot.user
        default:
            return nil
        }
    }
    
    /// Display name for the state
    var displayName: String {
        switch self {
        case .launching: return "Launching"
        case .authenticated: return "Ready"
        case .unauthenticated: return "Sign In Required"
        case .offline: return "Offline"
        case .locked: return "Locked"
        case .error: return "Error"
        case .syncing: return "Syncing"
        }
    }
    
    /// Icon for the state
    var icon: String {
        switch self {
        case .launching: return "hourglass"
        case .authenticated: return "checkmark.circle.fill"
        case .unauthenticated: return "person.crop.circle.badge.questionmark"
        case .offline: return "wifi.slash"
        case .locked: return "lock.fill"
        case .error: return "exclamationmark.triangle.fill"
        case .syncing: return "arrow.triangle.2.circlepath"
        }
    }
}

// MARK: - State Snapshot

/// Snapshot of state for restoration after transient states
struct AppStateSnapshot: Equatable, Sendable {
    let wasAuthenticated: Bool
    let user: User?
    let timestamp: Date
    
    init(from state: AppState) {
        self.wasAuthenticated = state.isAuthenticated
        self.user = state.currentUser
        self.timestamp = Date()
    }
}

// MARK: - App State Error

/// Errors that can put the app in an error state
struct AppStateError: Equatable, Sendable {
    let code: ErrorCode
    let message: String
    let underlyingError: String?
    let canRetry: Bool
    let timestamp: Date
    
    enum ErrorCode: String, Sendable {
        case networkFailure
        case authenticationFailure
        case dataCorruption
        case syncFailure
        case unknown
    }
    
    init(
        code: ErrorCode,
        message: String,
        underlyingError: Error? = nil,
        canRetry: Bool = true
    ) {
        self.code = code
        self.message = message
        self.underlyingError = underlyingError?.localizedDescription
        self.canRetry = canRetry
        self.timestamp = Date()
    }
    
    static func == (lhs: AppStateError, rhs: AppStateError) -> Bool {
        lhs.code == rhs.code && lhs.message == rhs.message && lhs.timestamp == rhs.timestamp
    }
}

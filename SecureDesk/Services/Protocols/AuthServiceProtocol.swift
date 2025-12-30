//
//  AuthServiceProtocol.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation

/// Protocol defining authentication operations
/// Implementations can be swapped between mock and real services
protocol AuthServiceProtocol: Sendable {
    
    /// Authenticate user with email and password
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    /// - Returns: Authentication token on success
    /// - Throws: AuthError on failure
    func login(email: String, password: String) async throws -> AuthToken
    
    /// Log out the current user
    /// - Throws: AuthError on failure
    func logout() async throws
    
    /// Refresh the current access token
    /// - Returns: New authentication token
    /// - Throws: AuthError on failure
    func refreshToken() async throws -> AuthToken
    
    /// Check if user is currently authenticated
    var isAuthenticated: Bool { get }
    
    /// Get the current authentication token if available
    var currentToken: AuthToken? { get }
    
    /// Get the currently authenticated user
    var currentUser: User? { get }
}

// MARK: - Auth Errors

/// Errors that can occur during authentication
enum AuthError: LocalizedError, Equatable {
    case invalidCredentials
    case networkError(String)
    case tokenExpired
    case noToken
    case serverError(String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError(let message):
            return "Network error: \(message)"
        case .tokenExpired:
            return "Your session has expired. Please log in again."
        case .noToken:
            return "No authentication token found"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

//
//  UserServiceProtocol.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation

/// Protocol defining user-related operations
protocol UserServiceProtocol: Sendable {
    
    /// Get the currently authenticated user's profile
    /// - Returns: Current user's profile
    /// - Throws: UserError on failure
    func getCurrentUser() async throws -> User
    
    /// Update the user's profile
    /// - Parameter user: Updated user data
    /// - Returns: Updated user profile
    /// - Throws: UserError on failure
    func updateProfile(_ user: User) async throws -> User
    
    /// Get a specific user by ID
    /// - Parameter id: User's unique identifier
    /// - Returns: User profile
    /// - Throws: UserError on failure
    func getUser(byId id: String) async throws -> User
    
    /// Search for users
    /// - Parameter query: Search query string
    /// - Returns: Array of matching users
    /// - Throws: UserError on failure
    func searchUsers(query: String) async throws -> [User]
}

// MARK: - User Errors

/// Errors that can occur during user operations
enum UserError: LocalizedError, Equatable {
    case notFound
    case unauthorized
    case validationError(String)
    case networkError(String)
    case serverError(String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "User not found"
        case .unauthorized:
            return "You don't have permission to perform this action"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

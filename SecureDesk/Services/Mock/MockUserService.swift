//
//  MockUserService.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation

/// Mock implementation of UserServiceProtocol for development and testing
final class MockUserService: UserServiceProtocol, Sendable {
    
    // MARK: - Mock Configuration
    
    /// Simulated network delay
    var networkDelay: TimeInterval {
        FeatureFlags.mockNetworkDelay
    }
    
    /// Whether to simulate network errors
    var shouldSimulateError = false
    
    // MARK: - Mock Data
    
    private let mockUsers: [User] = User.previewList
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - UserServiceProtocol
    
    func getCurrentUser() async throws -> User {
        try await Task.sleep(for: .seconds(networkDelay))
        
        if shouldSimulateError {
            throw UserError.networkError("Simulated network error")
        }
        
        return User.preview
    }
    
    func updateProfile(_ user: User) async throws -> User {
        try await Task.sleep(for: .seconds(networkDelay))
        
        if shouldSimulateError {
            throw UserError.networkError("Simulated network error")
        }
        
        // Validate
        guard !user.name.isEmpty else {
            throw UserError.validationError("Name cannot be empty")
        }
        
        guard user.email.contains("@") else {
            throw UserError.validationError("Invalid email format")
        }
        
        if FeatureFlags.enableVerboseLogging {
            print("[MockUserService] Profile updated for: \(user.email)")
        }
        
        return user
    }
    
    func getUser(byId id: String) async throws -> User {
        try await Task.sleep(for: .seconds(networkDelay))
        
        if shouldSimulateError {
            throw UserError.networkError("Simulated network error")
        }
        
        guard let user = mockUsers.first(where: { $0.id == id }) else {
            throw UserError.notFound
        }
        
        return user
    }
    
    func searchUsers(query: String) async throws -> [User] {
        try await Task.sleep(for: .seconds(networkDelay))
        
        if shouldSimulateError {
            throw UserError.networkError("Simulated network error")
        }
        
        let lowercasedQuery = query.lowercased()
        
        return mockUsers.filter { user in
            user.name.lowercased().contains(lowercasedQuery) ||
            user.email.lowercased().contains(lowercasedQuery)
        }
    }
}

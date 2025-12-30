//
//  MockAuthService.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation

/// Mock implementation of AuthServiceProtocol for development and testing
final class MockAuthService: AuthServiceProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    
    private let keychainService: any KeychainServiceProtocol
    private var _currentToken: AuthToken?
    private var _currentUser: User?
    private let lock = NSLock()
    
    var currentToken: AuthToken? {
        lock.lock()
        defer { lock.unlock() }
        return _currentToken
    }
    
    var currentUser: User? {
        lock.lock()
        defer { lock.unlock() }
        return _currentUser
    }
    
    var isAuthenticated: Bool {
        guard let token = currentToken else { return false }
        return !token.isExpired
    }
    
    // MARK: - Mock Configuration
    
    /// Simulated network delay
    var networkDelay: TimeInterval = FeatureFlags.mockNetworkDelay
    
    /// Whether to simulate network errors
    var shouldSimulateError = false
    
    /// Valid credentials for mock login
    private let validCredentials: [(email: String, password: String)] = [
        ("john.doe@example.com", "password123"),
        ("jane.smith@example.com", "password123"),
        ("demo@securedesk.app", "demo"),
        ("test@test.com", "test")
    ]
    
    // MARK: - Initialization
    
    init(keychainService: any KeychainServiceProtocol) {
        self.keychainService = keychainService
        
        // Try to restore token from keychain
        if let token = try? keychainService.load(AuthToken.self, forKey: KeychainKeys.authToken) {
            _currentToken = token
            _currentUser = User.preview
        }
    }
    
    // MARK: - AuthServiceProtocol
    
    func login(email: String, password: String) async throws -> AuthToken {
        // Simulate network delay
        try await Task.sleep(for: .seconds(networkDelay))
        
        // Simulate error if configured
        if shouldSimulateError {
            throw AuthError.networkError("Simulated network error")
        }
        
        // Validate credentials
        let isValid = validCredentials.contains { $0.email.lowercased() == email.lowercased() && $0.password == password } ||
                      (!email.isEmpty && !password.isEmpty) // Accept any non-empty credentials for demo
        
        guard isValid else {
            throw AuthError.invalidCredentials
        }
        
        // Create mock token
        let token = AuthToken(
            accessToken: "mock_access_token_\(UUID().uuidString)",
            refreshToken: "mock_refresh_token_\(UUID().uuidString)",
            expiresAt: Date().addingTimeInterval(3600), // 1 hour
            tokenType: "Bearer"
        )
        
        // Create mock user based on email
        let user = User(
            id: "usr_\(UUID().uuidString.prefix(8))",
            email: email,
            name: email.components(separatedBy: "@").first?.replacingOccurrences(of: ".", with: " ").capitalized ?? "User",
            avatarURL: URL(string: "https://api.dicebear.com/7.x/avataaars/svg?seed=\(email)"),
            createdAt: Date(),
            role: .member,
            isEmailVerified: true
        )
        
        // Store token in keychain
        try keychainService.save(token, forKey: KeychainKeys.authToken)
        
        lock.lock()
        _currentToken = token
        _currentUser = user
        lock.unlock()
        
        if FeatureFlags.enableVerboseLogging {
            print("[MockAuthService] Login successful for: \(email)")
        }
        
        return token
    }
    
    func logout() async throws {
        // Simulate network delay
        try await Task.sleep(for: .seconds(networkDelay / 2))
        
        // Clear keychain
        try keychainService.delete(forKey: KeychainKeys.authToken)
        
        lock.lock()
        _currentToken = nil
        _currentUser = nil
        lock.unlock()
        
        if FeatureFlags.enableVerboseLogging {
            print("[MockAuthService] Logout successful")
        }
    }
    
    func refreshToken() async throws -> AuthToken {
        // Simulate network delay
        try await Task.sleep(for: .seconds(networkDelay))
        
        guard currentToken != nil else {
            throw AuthError.noToken
        }
        
        // Create new mock token
        let newToken = AuthToken(
            accessToken: "mock_access_token_refreshed_\(UUID().uuidString)",
            refreshToken: "mock_refresh_token_refreshed_\(UUID().uuidString)",
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        
        // Store in keychain
        try keychainService.save(newToken, forKey: KeychainKeys.authToken)
        
        lock.lock()
        _currentToken = newToken
        lock.unlock()
        
        if FeatureFlags.enableVerboseLogging {
            print("[MockAuthService] Token refreshed")
        }
        
        return newToken
    }
}

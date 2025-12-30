//
//  AuthToken.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation

/// Represents authentication tokens returned from the auth service
struct AuthToken: Codable, Equatable, Sendable {
    
    /// JWT access token for API requests
    let accessToken: String
    
    /// Refresh token for obtaining new access tokens
    let refreshToken: String
    
    /// When the access token expires
    let expiresAt: Date
    
    /// Token type (usually "Bearer")
    let tokenType: String
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresAt = "expires_at"
        case tokenType = "token_type"
    }
    
    // MARK: - Computed Properties
    
    /// Whether the access token has expired
    var isExpired: Bool {
        Date() >= expiresAt
    }
    
    /// Whether the token will expire soon (within 5 minutes)
    var willExpireSoon: Bool {
        Date().addingTimeInterval(300) >= expiresAt
    }
    
    /// Authorization header value
    var authorizationHeader: String {
        "\(tokenType) \(accessToken)"
    }
}

// MARK: - Mock Data

extension AuthToken {
    /// Sample token for previews and testing
    static let preview = AuthToken(
        accessToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c3JfcHJldmlld18wMDEi" +
            "LCJlbWFpbCI6ImpvaG4uZG9lQGV4YW1wbGUuY29tIiwiaWF0IjoxNjk4NzY1NDMyLCJleHAiOjE2OTg3NjkwMzJ9.mock_signature",
        refreshToken: "refresh_token_mock_001",
        expiresAt: Date().addingTimeInterval(3600), // 1 hour from now
        tokenType: "Bearer"
    )
    
    /// Expired token for testing
    static let expired = AuthToken(
        accessToken: "expired_access_token",
        refreshToken: "expired_refresh_token",
        expiresAt: Date().addingTimeInterval(-3600), // 1 hour ago
        tokenType: "Bearer"
    )
}

// MARK: - Login Request

/// Request body for login endpoint
struct LoginRequest: Codable, Sendable {
    let email: String
    let password: String
}

// MARK: - Login Response

/// Response from login endpoint
struct LoginResponse: Codable, Sendable {
    let token: AuthToken
    let user: User
}

// MARK: - Refresh Token Request

/// Request body for token refresh endpoint
struct RefreshTokenRequest: Codable, Sendable {
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case refreshToken = "refresh_token"
    }
}

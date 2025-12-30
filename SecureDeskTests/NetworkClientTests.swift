//
//  NetworkClientTests.swift
//  SecureDeskTests
//
//  Created by Vipin Saini
//

import XCTest
@testable import SecureDesk

final class NetworkClientTests: XCTestCase {
    
    var sut: NetworkClient!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = NetworkClient(baseURL: URL(string: "https://api.example.com")!)
    }
    
    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Auth Token Tests
    
    func testAuthToken_isExpired_returnsTrueForPastDate() {
        // Given
        let token = AuthToken(
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(-3600), // 1 hour ago
            tokenType: "Bearer"
        )
        
        // Then
        XCTAssertTrue(token.isExpired)
    }
    
    func testAuthToken_isExpired_returnsFalseForFutureDate() {
        // Given
        let token = AuthToken(
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(3600), // 1 hour from now
            tokenType: "Bearer"
        )
        
        // Then
        XCTAssertFalse(token.isExpired)
    }
    
    func testAuthToken_willExpireSoon_returnsTrueWithin5Minutes() {
        // Given
        let token = AuthToken(
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(180), // 3 minutes from now
            tokenType: "Bearer"
        )
        
        // Then
        XCTAssertTrue(token.willExpireSoon)
    }
    
    func testAuthToken_willExpireSoon_returnsFalseIfMoreThan5Minutes() {
        // Given
        let token = AuthToken(
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(600), // 10 minutes from now
            tokenType: "Bearer"
        )
        
        // Then
        XCTAssertFalse(token.willExpireSoon)
    }
    
    func testAuthToken_authorizationHeader_formatsCorrectly() {
        // Given
        let token = AuthToken(
            accessToken: "abc123",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(3600),
            tokenType: "Bearer"
        )
        
        // Then
        XCTAssertEqual(token.authorizationHeader, "Bearer abc123")
    }
    
    // MARK: - API Endpoint Tests
    
    func testAuthEndpoint_login_hasCorrectPath() {
        // Given
        let endpoint = AuthEndpoint.login(email: "test@test.com", password: "pass")
        
        // Then
        XCTAssertEqual(endpoint.path, "/auth/login")
        XCTAssertEqual(endpoint.method, .post)
    }
    
    func testAuthEndpoint_logout_hasCorrectPath() {
        // Given
        let endpoint = AuthEndpoint.logout
        
        // Then
        XCTAssertEqual(endpoint.path, "/auth/logout")
        XCTAssertEqual(endpoint.method, .post)
    }
    
    func testUserEndpoint_getCurrentUser_hasCorrectPath() {
        // Given
        let endpoint = UserEndpoint.getCurrentUser
        
        // Then
        XCTAssertEqual(endpoint.path, "/users/me")
        XCTAssertEqual(endpoint.method, .get)
    }
    
    func testItemEndpoint_list_hasCorrectPath() {
        // Given
        let endpoint = ItemEndpoint.list(filter: nil)
        
        // Then
        XCTAssertEqual(endpoint.path, "/items")
        XCTAssertEqual(endpoint.method, .get)
    }
    
    func testItemEndpoint_delete_hasCorrectPath() {
        // Given
        let endpoint = ItemEndpoint.delete(id: "item123")
        
        // Then
        XCTAssertEqual(endpoint.path, "/items/item123")
        XCTAssertEqual(endpoint.method, .delete)
    }
    
    // MARK: - Network Error Tests
    
    func testNetworkError_hasLocalizedDescription() {
        // Given
        let errors: [NetworkError] = [
            .invalidURL,
            .invalidResponse,
            .unauthorized,
            .forbidden,
            .notFound,
            .validationError,
            .rateLimited,
            .serverError(500),
            .unexpectedStatusCode(418),
            .decodingError("Invalid JSON"),
            .encodingError,
            .noConnection,
            .timeout
        ]
        
        // Then
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
}

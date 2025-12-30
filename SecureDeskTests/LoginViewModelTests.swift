//
//  LoginViewModelTests.swift
//  SecureDeskTests
//
//  Created by Vipin Saini
//

import XCTest
@testable import SecureDesk

@MainActor
final class LoginViewModelTests: XCTestCase {
    
    var sut: LoginViewModel!
    var mockAuthService: MockAuthService!
    var mockKeychain: KeychainService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        mockKeychain = KeychainService(serviceName: "com.kf.SecureDesk.Tests.ViewModel")
        try? mockKeychain.deleteAll()
        mockAuthService = MockAuthService(keychainService: mockKeychain)
        sut = LoginViewModel(authService: mockAuthService)
    }
    
    override func tearDownWithError() throws {
        try? mockKeychain.deleteAll()
        mockKeychain = nil
        mockAuthService = nil
        sut = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Validation Tests
    
    func testIsFormValid_withEmptyEmail_returnsFalse() {
        // Given
        sut.email = ""
        sut.password = "password"
        
        // Then
        XCTAssertFalse(sut.isFormValid)
    }
    
    func testIsFormValid_withEmptyPassword_returnsFalse() {
        // Given
        sut.email = "test@example.com"
        sut.password = ""
        
        // Then
        XCTAssertFalse(sut.isFormValid)
    }
    
    func testIsFormValid_withValidCredentials_returnsTrue() {
        // Given
        sut.email = "test@example.com"
        sut.password = "password123"
        
        // Then
        XCTAssertTrue(sut.isFormValid)
    }
    
    func testIsFormValid_withWhitespaceEmail_returnsFalse() {
        // Given
        sut.email = "   "
        sut.password = "password"
        
        // Then
        XCTAssertFalse(sut.isFormValid)
    }
    
    // MARK: - Can Submit Tests
    
    func testCanSubmit_whenLoading_returnsFalse() {
        // Given
        sut.email = "test@example.com"
        sut.password = "password"
        sut.isLoading = true
        
        // Then
        XCTAssertFalse(sut.canSubmit)
    }
    
    func testCanSubmit_withValidForm_returnsTrue() {
        // Given
        sut.email = "test@example.com"
        sut.password = "password"
        sut.isLoading = false
        
        // Then
        XCTAssertTrue(sut.canSubmit)
    }
    
    // MARK: - Login Tests
    
    func testLogin_withValidCredentials_setsIsAuthenticated() async {
        // Given
        sut.email = "test@example.com"
        sut.password = "password"
        
        // When
        await sut.login()
        
        // Then
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNil(sut.errorMessage)
    }
    
    func testLogin_clearsPasswordAfterSuccess() async {
        // Given
        sut.email = "test@example.com"
        sut.password = "password123"
        
        // When
        await sut.login()
        
        // Then
        XCTAssertTrue(sut.password.isEmpty)
    }
    
    func testLogin_setsLoadingState() async {
        // Given
        sut.email = "test@example.com"
        sut.password = "password"
        mockAuthService.networkDelay = 0.1
        
        // When
        let task = Task {
            await sut.login()
        }
        
        // Brief delay to let loading state be set
        try? await Task.sleep(for: .milliseconds(50))
        XCTAssertTrue(sut.isLoading)
        
        await task.value
        XCTAssertFalse(sut.isLoading)
    }
    
    func testLogin_withError_setsErrorMessage() async {
        // Given
        sut.email = "test@example.com"
        sut.password = "password"
        mockAuthService.shouldSimulateError = true
        
        // When
        await sut.login()
        
        // Then
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNotNil(sut.errorMessage)
    }
    
    // MARK: - Clear Form Tests
    
    func testClearForm_resetsAllFields() {
        // Given
        sut.email = "test@example.com"
        sut.password = "password"
        sut.errorMessage = "Some error"
        
        // When
        sut.clearForm()
        
        // Then
        XCTAssertTrue(sut.email.isEmpty)
        XCTAssertTrue(sut.password.isEmpty)
        XCTAssertNil(sut.errorMessage)
    }
    
    // MARK: - Dismiss Error Tests
    
    func testDismissError_clearsErrorMessage() {
        // Given
        sut.errorMessage = "Some error"
        
        // When
        sut.dismissError()
        
        // Then
        XCTAssertNil(sut.errorMessage)
    }
}

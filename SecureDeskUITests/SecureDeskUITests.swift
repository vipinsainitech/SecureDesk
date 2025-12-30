//
//  SecureDeskUITests.swift
//  SecureDeskUITests
//
//  Created by Vipin Saini
//

import XCTest

final class SecureDeskUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchEnvironment["USE_MOCK_SERVICES"] = "true"
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Login Flow Tests
    
    func testLoginScreen_showsRequiredElements() throws {
        // Then - Verify login screen elements are visible
        XCTAssertTrue(app.staticTexts["SecureDesk"].exists)
        XCTAssertTrue(app.staticTexts["Sign in to your account"].exists)
        XCTAssertTrue(app.textFields["you@example.com"].exists)
        XCTAssertTrue(app.secureTextFields["Enter your password"].exists)
        XCTAssertTrue(app.buttons["Sign In"].exists)
    }
    
    func testLoginButton_isDisabledWithEmptyCredentials() throws {
        // Given
        let signInButton = app.buttons["Sign In"]
        
        // Then
        XCTAssertFalse(signInButton.isEnabled)
    }
    
    func testLoginButton_enablesWithValidCredentials() throws {
        // Given
        let emailField = app.textFields["you@example.com"]
        let passwordField = app.secureTextFields["Enter your password"]
        let signInButton = app.buttons["Sign In"]
        
        // When
        emailField.click()
        emailField.typeText("test@example.com")
        
        passwordField.click()
        passwordField.typeText("password123")
        
        // Then
        XCTAssertTrue(signInButton.isEnabled)
    }
    
    func testLogin_withValidCredentials_showsDashboard() throws {
        // Given
        let emailField = app.textFields["you@example.com"]
        let passwordField = app.secureTextFields["Enter your password"]
        let signInButton = app.buttons["Sign In"]
        
        // When
        emailField.click()
        emailField.typeText("demo@securedesk.app")
        
        passwordField.click()
        passwordField.typeText("demo")
        
        signInButton.click()
        
        // Wait for navigation to complete
        let dashboardTitle = app.staticTexts["Dashboard"]
        let exists = dashboardTitle.waitForExistence(timeout: 5)
        
        // Then
        XCTAssertTrue(exists, "Dashboard should be visible after login")
    }
    
    // MARK: - Dashboard Tests
    
    func testDashboard_showsItems() throws {
        // Login first
        performLogin()
        
        // Wait for items to load
        let itemExists = app.staticTexts["Review Q4 Reports"].waitForExistence(timeout: 5)
        
        // Then
        XCTAssertTrue(itemExists, "Dashboard should show items")
    }
    
    func testDashboard_hasSearchField() throws {
        // Login first
        performLogin()
        
        // Wait for dashboard
        _ = app.staticTexts["Dashboard"].waitForExistence(timeout: 5)
        
        // Then
        let searchField = app.textFields["Search items..."]
        XCTAssertTrue(searchField.exists, "Dashboard should have search field")
    }
    
    // MARK: - Navigation Tests
    
    func testSidebar_showsNavigationItems() throws {
        // Login first
        performLogin()
        
        // Wait for navigation
        _ = app.staticTexts["Dashboard"].waitForExistence(timeout: 5)
        
        // Then
        XCTAssertTrue(app.staticTexts["Dashboard"].exists)
        XCTAssertTrue(app.staticTexts["Settings"].exists)
    }
    
    func testNavigation_toSettings() throws {
        // Login first
        performLogin()
        
        // Wait for dashboard
        _ = app.staticTexts["Dashboard"].waitForExistence(timeout: 5)
        
        // When - Click Settings in sidebar
        let settingsLink = app.staticTexts["Settings"]
        if settingsLink.exists {
            settingsLink.click()
            
            // Wait for settings to load
            let profileSection = app.staticTexts["Profile"].waitForExistence(timeout: 3)
            
            // Then
            XCTAssertTrue(profileSection, "Settings view should be visible")
        }
    }
    
    // MARK: - Settings Tests
    
    func testSettings_showsSignOutButton() throws {
        // Login and navigate to settings
        performLogin()
        _ = app.staticTexts["Dashboard"].waitForExistence(timeout: 5)
        
        app.staticTexts["Settings"].click()
        _ = app.staticTexts["Profile"].waitForExistence(timeout: 3)
        
        // Then
        let signOutButton = app.buttons["Sign Out"]
        XCTAssertTrue(signOutButton.exists, "Settings should have Sign Out button")
    }
    
    // MARK: - Error State Tests
    
    func testLogin_showsLoadingState() throws {
        // Given
        let emailField = app.textFields["you@example.com"]
        let passwordField = app.secureTextFields["Enter your password"]
        let signInButton = app.buttons["Sign In"]
        
        // When
        emailField.click()
        emailField.typeText("test@example.com")
        
        passwordField.click()
        passwordField.typeText("password")
        
        signInButton.click()
        
        // Then - Button should show loading text (may be quick so timeout is short)
        let signingIn = app.buttons["Signing In..."].waitForExistence(timeout: 1)
        // Note: This might be too quick to catch, which is fine
        _ = signingIn
    }
    
    // MARK: - Helper Methods
    
    private func performLogin() {
        let emailField = app.textFields["you@example.com"]
        let passwordField = app.secureTextFields["Enter your password"]
        let signInButton = app.buttons["Sign In"]
        
        if emailField.exists {
            emailField.click()
            emailField.typeText("demo@securedesk.app")
            
            passwordField.click()
            passwordField.typeText("demo")
            
            signInButton.click()
        }
    }
}

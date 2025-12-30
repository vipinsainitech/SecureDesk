//
//  LoginViewModel.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation
import SwiftUI

/// View model for the login screen
@MainActor
@Observable
final class LoginViewModel {
    
    // MARK: - Published Properties
    
    var email = ""
    var password = ""
    var isLoading = false
    var errorMessage: String?
    var isAuthenticated = false
    
    // MARK: - Computed Properties
    
    var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }
    
    var canSubmit: Bool {
        isFormValid && !isLoading
    }
    
    // MARK: - Dependencies
    
    private let authService: any AuthServiceProtocol
    
    // MARK: - Initialization
    
    init(authService: any AuthServiceProtocol) {
        self.authService = authService
        self.isAuthenticated = authService.isAuthenticated
    }
    
    // MARK: - Actions
    
    /// Attempt to log in with current credentials
    func login() async {
        guard canSubmit else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            _ = try await authService.login(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            
            isAuthenticated = true
            
            // Notify app of successful login
            NotificationCenter.default.post(name: .userDidLogin, object: nil)
            
            // Clear sensitive data
            password = ""
            
        } catch let error as AuthError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "An unexpected error occurred. Please try again."
        }
        
        isLoading = false
    }
    
    /// Clear all form fields
    func clearForm() {
        email = ""
        password = ""
        errorMessage = nil
    }
    
    /// Dismiss error message
    func dismissError() {
        errorMessage = nil
    }
}

// MARK: - Preview

extension LoginViewModel {
    /// Preview instance with mock service
    static var preview: LoginViewModel {
        LoginViewModel(authService: MockAuthService(keychainService: KeychainService()))
    }
}

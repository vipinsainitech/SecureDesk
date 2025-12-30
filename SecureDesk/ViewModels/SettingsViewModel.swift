//
//  SettingsViewModel.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation
import SwiftUI

/// View model for the settings screen
@MainActor
@Observable
final class SettingsViewModel {
    
    // MARK: - Published Properties
    
    var currentUser: User?
    var isLoading = false
    var errorMessage: String?
    var successMessage: String?
    
    // Profile editing
    var editedName = ""
    var editedEmail = ""
    var isEditingProfile = false
    var isSavingProfile = false
    
    // Preferences
    var useMockServices: Bool {
        didSet {
            #if DEBUG
            FeatureFlags.setUseMockServices(useMockServices)
            #endif
        }
    }
    
    // MARK: - Computed Properties
    
    var hasUnsavedChanges: Bool {
        guard let user = currentUser else { return false }
        return editedName != user.name || editedEmail != user.email
    }
    
    var canSaveProfile: Bool {
        !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        editedEmail.contains("@") &&
        hasUnsavedChanges &&
        !isSavingProfile
    }
    
    // MARK: - Dependencies
    
    private let userService: any UserServiceProtocol
    private let authService: any AuthServiceProtocol
    
    // MARK: - Initialization
    
    init(userService: any UserServiceProtocol, authService: any AuthServiceProtocol) {
        self.userService = userService
        self.authService = authService
        self.useMockServices = FeatureFlags.useMockServices
    }
    
    // MARK: - Actions
    
    /// Load user data
    func loadUser() async {
        isLoading = true
        errorMessage = nil
        
        do {
            currentUser = try await userService.getCurrentUser()
            resetEditedFields()
        } catch {
            errorMessage = "Failed to load user data"
        }
        
        isLoading = false
    }
    
    /// Start editing profile
    func startEditing() {
        resetEditedFields()
        isEditingProfile = true
    }
    
    /// Cancel editing
    func cancelEditing() {
        resetEditedFields()
        isEditingProfile = false
    }
    
    /// Save profile changes
    func saveProfile() async {
        guard let user = currentUser, canSaveProfile else { return }
        
        isSavingProfile = true
        errorMessage = nil
        successMessage = nil
        
        let updatedUser = User(
            id: user.id,
            email: editedEmail.trimmingCharacters(in: .whitespacesAndNewlines),
            name: editedName.trimmingCharacters(in: .whitespacesAndNewlines),
            avatarURL: user.avatarURL,
            createdAt: user.createdAt,
            role: user.role,
            isEmailVerified: user.isEmailVerified
        )
        
        do {
            currentUser = try await userService.updateProfile(updatedUser)
            isEditingProfile = false
            successMessage = "Profile updated successfully"
            
            // Clear success message after delay
            Task {
                try? await Task.sleep(for: .seconds(3))
                successMessage = nil
            }
        } catch let error as UserError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to update profile"
        }
        
        isSavingProfile = false
    }
    
    /// Log out the user
    func logout() async {
        isLoading = true
        
        do {
            try await authService.logout()
        } catch {
            errorMessage = "Failed to log out"
        }
        
        isLoading = false
    }
    
    /// Dismiss messages
    func dismissMessages() {
        errorMessage = nil
        successMessage = nil
    }
    
    // MARK: - Private Methods
    
    private func resetEditedFields() {
        editedName = currentUser?.name ?? ""
        editedEmail = currentUser?.email ?? ""
    }
}

// MARK: - App Info

extension SettingsViewModel {
    /// App version string
    var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    /// Build configuration
    var buildConfiguration: String {
        #if DEBUG
        return "Debug"
        #else
        return "Release"
        #endif
    }
}

// MARK: - Preview

extension SettingsViewModel {
    /// Preview instance with mock data
    static var preview: SettingsViewModel {
        let vm = SettingsViewModel(
            userService: MockUserService(),
            authService: MockAuthService(keychainService: KeychainService())
        )
        vm.currentUser = User.preview
        vm.editedName = User.preview.name
        vm.editedEmail = User.preview.email
        return vm
    }
}

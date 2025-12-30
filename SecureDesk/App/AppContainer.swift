//
//  AppContainer.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation
import SwiftUI

/// Dependency injection container for the application
/// Provides service instances based on feature flags
@MainActor
final class AppContainer {
    
    // MARK: - Shared Instance
    
    static let shared = AppContainer()
    
    // MARK: - Private Storage
    
    private var _authService: (any AuthServiceProtocol)?
    private var _userService: (any UserServiceProtocol)?
    private var _itemService: (any ItemServiceProtocol)?
    private var _keychainService: (any KeychainServiceProtocol)?
    private var _encryptionService: (any EncryptionServiceProtocol)?
    private var _networkClient: NetworkClient?
    
    // MARK: - Services
    
    /// Authentication service
    var authService: any AuthServiceProtocol {
        if let service = _authService { return service }
        let service: any AuthServiceProtocol
        if FeatureFlags.useMockServices {
            service = MockAuthService(keychainService: keychainService)
        } else {
            // TODO: Return real AuthService when backend is ready
            service = MockAuthService(keychainService: keychainService)
        }
        _authService = service
        return service
    }
    
    /// User service
    var userService: any UserServiceProtocol {
        if let service = _userService { return service }
        let service: any UserServiceProtocol
        if FeatureFlags.useMockServices {
            service = MockUserService()
        } else {
            // TODO: Return real UserService when backend is ready
            service = MockUserService()
        }
        _userService = service
        return service
    }
    
    /// Item service
    var itemService: any ItemServiceProtocol {
        if let service = _itemService { return service }
        let service: any ItemServiceProtocol
        if FeatureFlags.useMockServices {
            service = MockItemService()
        } else {
            // TODO: Return real ItemService when backend is ready
            service = MockItemService()
        }
        _itemService = service
        return service
    }
    
    /// Keychain service for secure storage
    var keychainService: any KeychainServiceProtocol {
        if let service = _keychainService { return service }
        let service = KeychainService()
        _keychainService = service
        return service
    }
    
    /// Encryption service for data protection
    var encryptionService: any EncryptionServiceProtocol {
        if let service = _encryptionService { return service }
        let service = EncryptionService()
        _encryptionService = service
        return service
    }
    
    /// Network client for API requests
    var networkClient: NetworkClient {
        if let client = _networkClient { return client }
        let client = NetworkClient(baseURL: FeatureFlags.apiBaseURL)
        _networkClient = client
        return client
    }
    
    // MARK: - View Models
    
    /// Creates a new LoginViewModel instance
    func makeLoginViewModel() -> LoginViewModel {
        LoginViewModel(authService: authService)
    }
    
    /// Creates a new DashboardViewModel instance
    func makeDashboardViewModel() -> DashboardViewModel {
        DashboardViewModel(
            itemService: itemService,
            userService: userService
        )
    }
    
    /// Creates a new SettingsViewModel instance
    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(
            userService: userService,
            authService: authService
        )
    }
    
    // MARK: - Initialization
    
    private init() {
        if FeatureFlags.enableVerboseLogging {
            print("[AppContainer] Initialized with mock services: \(FeatureFlags.useMockServices)")
        }
    }
    
    // MARK: - Testing Support
    
    #if DEBUG
    /// Creates a container with mock services for testing
    static func forTesting() -> AppContainer {
        let container = AppContainer()
        return container
    }
    
    /// Creates a container with preview data
    static func forPreview() -> AppContainer {
        AppContainer()
    }
    #endif
}

// MARK: - Environment Key

private struct AppContainerKey: EnvironmentKey {
    @MainActor static let defaultValue = AppContainer.shared
}

extension EnvironmentValues {
    var appContainer: AppContainer {
        get { self[AppContainerKey.self] }
        set { self[AppContainerKey.self] = newValue }
    }
}

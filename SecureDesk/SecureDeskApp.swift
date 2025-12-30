//
//  SecureDeskApp.swift
//  SecureDesk
//
//  Created by Vipin Saini on 30/12/25.
//

import SwiftUI
import AppKit

@main
struct SecureDeskApp: App {
    
    // MARK: - AppKit Integration
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // MARK: - State
    
    @State private var container = AppContainer.shared
    @State private var isAuthenticated = false
    @State private var showingUpdateCheck = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isAuthenticated {
                    MainNavigationView()
                        .environment(\.appContainer, container)
                        .environment(\.featureFlags, FeatureFlagManager.shared)
                        .environment(\.environmentManager, EnvironmentManager.shared)
                        .environment(\.appStateManager, AppStateManager.shared)
                        .environment(\.networkMonitor, NetworkMonitor.shared)
                        .environment(\.securityManager, SecurityManager.shared)
                } else {
                    LoginView(viewModel: container.makeLoginViewModel())
                        .onReceive(NotificationCenter.default.publisher(for: .userDidLogin)) { _ in
                            withAnimation {
                                isAuthenticated = true
                            }
                        }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .userDidLogout)) { _ in
                withAnimation {
                    isAuthenticated = false
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .checkForUpdatesRequested)) { _ in
                showingUpdateCheck = true
            }
            .onAppear {
                setupApp()
            }
            .alert("Check for Updates", isPresented: $showingUpdateCheck) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("You're running the latest version of SecureDesk.")
            }
            // Window configuration
            .configureWindow(
                minSize: CGSize(width: 900, height: 600),
                titlebarAppearsTransparent: false,
                titleVisibility: .visible
            )
        }
        .windowStyle(.automatic)
        .windowToolbarStyle(.unified)
        .commands {
            // File Menu
            CommandGroup(replacing: .newItem) {
                Button("New Item") {
                    NotificationCenter.default.post(name: .newItemRequested, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
                .disabled(!isAuthenticated)
                
                Divider()
                
                Button("Import Items...") {
                    Task {
                        if let items = await ExportService.importItems() {
                            print("[Import] Loaded \(items.count) items")
                        }
                    }
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
                .disabled(!isAuthenticated)
                
                Button("Export Items...") {
                    Task {
                        // Placeholder - would export current items from view model
                        await ExportService.exportItems([])
                    }
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(!isAuthenticated)
            }
            
            // App Menu
            CommandGroup(after: .appInfo) {
                Divider()
                Button("Check for Updates...") {
                    NotificationCenter.default.post(name: .checkForUpdatesRequested, object: nil)
                }
            }
            
            // View Menu
            CommandGroup(after: .sidebar) {
                Button("Refresh") {
                    NotificationCenter.default.post(name: .refreshRequested, object: nil)
                    HapticFeedback.success()
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(!isAuthenticated)
                
                Divider()
                
                Button("Show All Items") {
                    NotificationCenter.default.post(name: .clearFiltersRequested, object: nil)
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
                .disabled(!isAuthenticated)
            }
            
            // Debug Menu (DEBUG only)
            #if DEBUG
            CommandMenu("Debug") {
                Button("Open Debug Menu") {
                    // Post notification to open debug menu
                    NotificationCenter.default.post(name: .openDebugMenuRequested, object: nil)
                }
                .keyboardShortcut("d", modifiers: [.command, .shift])
                
                Divider()
                
                Menu("Environment") {
                    ForEach(AppEnvironment.allCases) { env in
                        Button(env.displayName) {
                            EnvironmentManager.shared.switchTo(env)
                        }
                    }
                }
                
                Divider()
                
                Button("Reset All Settings") {
                    FeatureFlagManager.shared.resetAllToDefaults()
                    EnvironmentManager.shared.resetToDefault()
                }
            }
            #endif
        }
        
        // Settings Window
        #if os(macOS)
        Settings {
            PreferencesView()
                .environment(\.appContainer, container)
                .environment(\.featureFlags, FeatureFlagManager.shared)
                .environment(\.environmentManager, EnvironmentManager.shared)
                .environment(\.securityManager, SecurityManager.shared)
        }
        #endif
    }
    
    // MARK: - Setup
    
    private func setupApp() {
        // Check if user is already authenticated
        isAuthenticated = container.authService.isAuthenticated
        
        // Start network monitoring
        NetworkMonitor.shared.startMonitoring()
        
        // Enable menu bar if configured
        if FeatureFlagManager.shared.isEnabled(.enableDebugMenu) {
            MenuBarManager.shared.enable()
        }
        
        // Log startup
        logInfo("SecureDesk started", category: "App")
        logInfo("Environment: \(EnvironmentManager.shared.current.displayName)", category: "App")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
    static let userDidLogout = Notification.Name("userDidLogout")
    static let newItemRequested = Notification.Name("newItemRequested")
    static let checkForUpdatesRequested = Notification.Name("checkForUpdatesRequested")
    static let refreshRequested = Notification.Name("refreshRequested")
    static let clearFiltersRequested = Notification.Name("clearFiltersRequested")
    static let openDebugMenuRequested = Notification.Name("openDebugMenuRequested")
}


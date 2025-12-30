//
//  DebugMenuView.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

#if DEBUG

import SwiftUI

/// Debug menu for development and testing
/// Only available in DEBUG builds
struct DebugMenuView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.featureFlags) private var featureFlags
    @Environment(\.environmentManager) private var environmentManager
    @Environment(\.appStateManager) private var appStateManager
    @Environment(\.networkMonitor) private var networkMonitor
    
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            featureFlagsTab
                .tabItem { Label("Flags", systemImage: "flag") }
                .tag(0)
            
            environmentTab
                .tabItem { Label("Environment", systemImage: "gearshape.2") }
                .tag(1)
            
            stateTab
                .tabItem { Label("State", systemImage: "cpu") }
                .tag(2)
            
            networkTab
                .tabItem { Label("Network", systemImage: "network") }
                .tag(3)
            
            actionsTab
                .tabItem { Label("Actions", systemImage: "bolt") }
                .tag(4)
        }
        .frame(width: 500, height: 450)
    }
    
    // MARK: - Feature Flags Tab
    
    private var featureFlagsTab: some View {
        List {
            ForEach(FeatureFlagCategory.allCases) { category in
                Section(category.rawValue) {
                    ForEach(category.flags) { flag in
                        Toggle(isOn: Binding(
                            get: { featureFlags.isEnabled(flag) },
                            set: { featureFlags.setEnabled(flag, enabled: $0) }
                        )) {
                            VStack(alignment: .leading) {
                                Text(flag.displayName)
                                Text(flag.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .disabled(flag.isDebugOnly == false && flag.defaultValue == featureFlags.isEnabled(flag))
                    }
                }
            }
            
            Section {
                Button("Reset All to Defaults") {
                    featureFlags.resetAllToDefaults()
                }
                .foregroundStyle(.red)
            }
        }
        .listStyle(.inset)
    }
    
    // MARK: - Environment Tab
    
    private var environmentTab: some View {
        List {
            Section("Current Environment") {
                ForEach(AppEnvironment.allCases) { env in
                    HStack {
                        Image(systemName: env.icon)
                            .foregroundStyle(colorFor(env))
                        
                        VStack(alignment: .leading) {
                            Text(env.displayName)
                                .fontWeight(environmentManager.current == env ? .semibold : .regular)
                            Text(env.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if environmentManager.current == env {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        environmentManager.switchTo(env)
                    }
                }
            }
            
            Section("Configuration") {
                LabeledContent("Base URL") {
                    Text(environmentManager.baseURL.absoluteString)
                        .font(.caption)
                        .textSelection(.enabled)
                }
                
                LabeledContent("Mock Services") {
                    Text(environmentManager.useMockServices ? "Yes" : "No")
                }
                
                LabeledContent("Request Timeout") {
                    Text("\(Int(environmentManager.requestTimeout))s")
                }
            }
        }
        .listStyle(.inset)
    }
    
    // MARK: - State Tab
    
    private var stateTab: some View {
        List {
            Section("Current State") {
                HStack {
                    Image(systemName: appStateManager.currentState.icon)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text(appStateManager.currentState.displayName)
                            .font(.headline)
                        
                        if let user = appStateManager.currentState.currentUser {
                            Text(user.email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            
            Section("Properties") {
                LabeledContent("Is Authenticated") {
                    Text(appStateManager.currentState.isAuthenticated ? "Yes" : "No")
                }
                
                LabeledContent("Is Usable") {
                    Text(appStateManager.currentState.isUsable ? "Yes" : "No")
                }
                
                LabeledContent("Is Transitional") {
                    Text(appStateManager.currentState.isTransitional ? "Yes" : "No")
                }
            }
            
            Section("Actions") {
                Button("Force Lock") {
                    appStateManager.lock()
                }
                
                Button("Force Offline") {
                    appStateManager.enterOfflineMode()
                }
                
                Button("Simulate Error") {
                    let error = AppStateError(code: .unknown, message: "Simulated error")
                    appStateManager.setError(error)
                }
            }
        }
        .listStyle(.inset)
    }
    
    // MARK: - Network Tab
    
    private var networkTab: some View {
        List {
            Section("Status") {
                HStack {
                    Image(systemName: networkMonitor.connectionType.icon)
                        .font(.title2)
                        .foregroundStyle(networkMonitor.isConnected ? .green : .red)
                    
                    VStack(alignment: .leading) {
                        Text(networkMonitor.isConnected ? "Connected" : "Disconnected")
                            .font(.headline)
                        Text(networkMonitor.connectionType.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            Section("Details") {
                LabeledContent("Expensive") {
                    Text(networkMonitor.isExpensive ? "Yes" : "No")
                }
                
                LabeledContent("Constrained") {
                    Text(networkMonitor.isConstrained ? "Yes" : "No")
                }
                
                LabeledContent("Last Change") {
                    Text(networkMonitor.lastStatusChange, style: .relative)
                }
            }
        }
        .listStyle(.inset)
    }
    
    // MARK: - Actions Tab
    
    private var actionsTab: some View {
        List {
            Section("Cache") {
                Button("Clear All Cache") {
                    Task {
                        // Would call persistence service
                        print("[Debug] Cache cleared")
                    }
                }
                
                Button("Reset User Defaults") {
                    if let bundleId = Bundle.main.bundleIdentifier {
                        UserDefaults.standard.removePersistentDomain(forName: bundleId)
                    }
                }
                .foregroundStyle(.red)
            }
            
            Section("Authentication") {
                Button("Force Logout") {
                    appStateManager.logout()
                    NotificationCenter.default.post(name: .userDidLogout, object: nil)
                }
                .foregroundStyle(.red)
                
                Button("Expire Token") {
                    // Would call auth service
                    print("[Debug] Token expired")
                }
            }
            
            Section("Notifications") {
                Button("Post Login Notification") {
                    NotificationCenter.default.post(name: .userDidLogin, object: nil)
                }
                
                Button("Post Logout Notification") {
                    NotificationCenter.default.post(name: .userDidLogout, object: nil)
                }
            }
        }
        .listStyle(.inset)
    }
    
    // MARK: - Helpers
    
    private func colorFor(_ env: AppEnvironment) -> Color {
        switch env {
        case .mock: return .orange
        case .staging: return .yellow
        case .production: return .green
        }
    }
}

// MARK: - Debug Menu Button

/// Button to open debug menu
struct DebugMenuButton: View {
    
    @State private var showingDebugMenu = false
    
    var body: some View {
        Button {
            showingDebugMenu = true
        } label: {
            Image(systemName: "ladybug")
        }
        .sheet(isPresented: $showingDebugMenu) {
            DebugMenuView()
        }
        .keyboardShortcut("d", modifiers: [.command, .shift])
    }
}

// MARK: - Preview

#Preview {
    DebugMenuView()
}

#endif

//
//  PreferencesView.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import SwiftUI

/// Native macOS Preferences window
struct PreferencesView: View {
    
    private enum Tab: String, CaseIterable {
        case general = "General"
        case account = "Account"
        case advanced = "Advanced"
        
        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .account: return "person.circle"
            case .advanced: return "wrench.and.screwdriver"
            }
        }
    }
    
    @State private var selectedTab: Tab = .general
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralPreferencesTab()
                .tabItem {
                    Label(Tab.general.rawValue, systemImage: Tab.general.icon)
                }
                .tag(Tab.general)
            
            AccountPreferencesTab()
                .tabItem {
                    Label(Tab.account.rawValue, systemImage: Tab.account.icon)
                }
                .tag(Tab.account)
            
            #if DEBUG
            AdvancedPreferencesTab()
                .tabItem {
                    Label(Tab.advanced.rawValue, systemImage: Tab.advanced.icon)
                }
                .tag(Tab.advanced)
            #endif
        }
        .frame(width: 450, height: 350)
    }
}

// MARK: - General Preferences

struct GeneralPreferencesTab: View {
    
    @Environment(\.featureFlags) private var featureFlags
    
    @State private var launchAtLogin = false
    @State private var showInMenuBar = false
    
    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at login", isOn: $launchAtLogin)
                Toggle("Show in menu bar", isOn: $showInMenuBar)
            }
            
            Section("Features") {
                Toggle("Enable keyboard shortcuts", isOn: Binding(
                    get: { featureFlags.isEnabled(.enableKeyboardShortcuts) },
                    set: { featureFlags.setEnabled(.enableKeyboardShortcuts, enabled: $0) }
                ))
                
                Toggle("Enable offline mode", isOn: Binding(
                    get: { featureFlags.isEnabled(.enableOfflineMode) },
                    set: { featureFlags.setEnabled(.enableOfflineMode, enabled: $0) }
                ))
                
                Toggle("Enable advanced search", isOn: Binding(
                    get: { featureFlags.isEnabled(.enableAdvancedSearch) },
                    set: { featureFlags.setEnabled(.enableAdvancedSearch, enabled: $0) }
                ))
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Account Preferences

struct AccountPreferencesTab: View {
    
    @Environment(\.securityManager) private var securityManager
    @Environment(\.featureFlags) private var featureFlags
    
    @State private var autoLockTimeout: Double = 300
    
    var body: some View {
        Form {
            Section("Security") {
                Toggle("Enable auto-lock", isOn: Binding(
                    get: { featureFlags.isEnabled(.enableAutoLock) },
                    set: { featureFlags.setEnabled(.enableAutoLock, enabled: $0) }
                ))
                
                if featureFlags.isEnabled(.enableAutoLock) {
                    Picker("Lock after", selection: $autoLockTimeout) {
                        Text("1 minute").tag(60.0)
                        Text("5 minutes").tag(300.0)
                        Text("15 minutes").tag(900.0)
                        Text("30 minutes").tag(1800.0)
                    }
                    .onChange(of: autoLockTimeout) { _, newValue in
                        securityManager.autoLockTimeout = newValue
                    }
                }
                
                if securityManager.isBiometricAvailable {
                    Toggle("Enable \(securityManager.biometricType.displayName)", isOn: Binding(
                        get: { featureFlags.isEnabled(.enableBiometricAuth) },
                        set: { featureFlags.setEnabled(.enableBiometricAuth, enabled: $0) }
                    ))
                }
            }
            
            Section("Session") {
                Button("Sign Out") {
                    NotificationCenter.default.post(name: .userDidLogout, object: nil)
                }
                .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Advanced Preferences (DEBUG only)

#if DEBUG
struct AdvancedPreferencesTab: View {
    
    @Environment(\.environmentManager) private var environmentManager
    @Environment(\.featureFlags) private var featureFlags
    
    var body: some View {
        Form {
            Section("Environment") {
                Picker("Environment", selection: Binding(
                    get: { environmentManager.current },
                    set: { environmentManager.switchTo($0) }
                )) {
                    ForEach(environmentManager.availableEnvironments) { env in
                        Text(env.displayName).tag(env)
                    }
                }
                
                LabeledContent("Base URL") {
                    Text(environmentManager.baseURL.absoluteString)
                        .font(.caption)
                        .textSelection(.enabled)
                }
            }
            
            Section("Developer") {
                Toggle("Enable debug menu", isOn: Binding(
                    get: { featureFlags.isEnabled(.enableDebugMenu) },
                    set: { featureFlags.setEnabled(.enableDebugMenu, enabled: $0) }
                ))
                
                Toggle("Verbose logging", isOn: Binding(
                    get: { featureFlags.isEnabled(.enableVerboseLogging) },
                    set: { featureFlags.setEnabled(.enableVerboseLogging, enabled: $0) }
                ))
                
                Toggle("Network logging", isOn: Binding(
                    get: { featureFlags.isEnabled(.enableNetworkLogging) },
                    set: { featureFlags.setEnabled(.enableNetworkLogging, enabled: $0) }
                ))
            }
            
            Section("Storage") {
                Button("Clear Cache") {
                    Task {
                        // Would clear persistence
                        print("[Preferences] Cache cleared")
                    }
                }
                
                Button("Reset All Settings") {
                    featureFlags.resetAllToDefaults()
                    environmentManager.resetToDefault()
                }
                .foregroundStyle(.red)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
#endif

// MARK: - Preview

#Preview {
    PreferencesView()
}

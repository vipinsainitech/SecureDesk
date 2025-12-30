//
//  MenuBarExtra.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import SwiftUI
import AppKit

/// Menu bar extra (status bar icon) for SecureDesk
/// Provides quick access to app features from the menu bar
@MainActor
@Observable
final class MenuBarManager {
    
    // MARK: - Singleton
    
    static let shared = MenuBarManager()
    
    // MARK: - Properties
    
    private var statusItem: NSStatusItem?
    private var isEnabled: Bool = false
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Enable the menu bar extra
    func enable() {
        guard !isEnabled else { return }
        isEnabled = true
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "lock.shield.fill", accessibilityDescription: "SecureDesk")
            button.image?.isTemplate = true
        }
        
        statusItem?.menu = createMenu()
    }
    
    /// Disable the menu bar extra
    func disable() {
        guard isEnabled else { return }
        isEnabled = false
        
        if let statusItem = statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil
    }
    
    /// Toggle menu bar extra
    func toggle() {
        if isEnabled {
            disable()
        } else {
            enable()
        }
    }
    
    /// Update the menu
    func updateMenu() {
        statusItem?.menu = createMenu()
    }
    
    // MARK: - Private Methods
    
    private func createMenu() -> NSMenu {
        let menu = NSMenu()
        
        // Header
        let headerItem = NSMenuItem(title: "SecureDesk", action: nil, keyEquivalent: "")
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        menu.addItem(NSMenuItem.separator())
        
        // Quick Actions
        addQuickActions(to: menu)
        menu.addItem(NSMenuItem.separator())
        
        // Status
        addStatusSubmenu(to: menu)
        menu.addItem(NSMenuItem.separator())
        
        // Footer actions
        addFooterActions(to: menu)
        
        return menu
    }
    
    private func addQuickActions(to menu: NSMenu) {
        let newItemAction = NSMenuItem(
            title: "New Item",
            action: #selector(newItemAction(_:)),
            keyEquivalent: "n"
        )
        newItemAction.target = self
        newItemAction.keyEquivalentModifierMask = [.command]
        menu.addItem(newItemAction)
        
        let refreshAction = NSMenuItem(
            title: "Refresh",
            action: #selector(refreshAction(_:)),
            keyEquivalent: "r"
        )
        refreshAction.target = self
        refreshAction.keyEquivalentModifierMask = [.command]
        menu.addItem(refreshAction)
    }
    
    private func addStatusSubmenu(to menu: NSMenu) {
        let statusSubmenu = NSMenu()
        
        let networkMonitor = NetworkMonitor.shared
        let networkItem = NSMenuItem(
            title: networkMonitor.isConnected ? "Online" : "Offline",
            action: nil,
            keyEquivalent: ""
        )
        networkItem.image = NSImage(
            systemSymbolName: networkMonitor.isConnected ? "wifi" : "wifi.slash",
            accessibilityDescription: nil
        )
        statusSubmenu.addItem(networkItem)
        
        let environmentItem = NSMenuItem(
            title: "Environment: \(EnvironmentManager.shared.current.displayName)",
            action: nil,
            keyEquivalent: ""
        )
        statusSubmenu.addItem(environmentItem)
        
        let statusItem = NSMenuItem(title: "Status", action: nil, keyEquivalent: "")
        statusItem.submenu = statusSubmenu
        menu.addItem(statusItem)
    }
    
    private func addFooterActions(to menu: NSMenu) {
        let openAppAction = NSMenuItem(
            title: "Open SecureDesk",
            action: #selector(openAppAction(_:)),
            keyEquivalent: ""
        )
        openAppAction.target = self
        menu.addItem(openAppAction)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitAction = NSMenuItem(
            title: "Quit SecureDesk",
            action: #selector(quitAction(_:)),
            keyEquivalent: "q"
        )
        quitAction.target = self
        quitAction.keyEquivalentModifierMask = [.command]
        menu.addItem(quitAction)
    }
    
    // MARK: - Actions
    
    @objc private func newItemAction(_ sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(name: .newItemRequested, object: nil)
    }
    
    @objc private func refreshAction(_ sender: Any?) {
        NotificationCenter.default.post(name: .refreshRequested, object: nil)
    }
    
    @objc private func openAppAction(_ sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)
        
        // Ensure main window is shown
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc private func quitAction(_ sender: Any?) {
        NSApp.terminate(nil)
    }
}

// MARK: - SwiftUI MenuBarExtra (Alternative)

/// SwiftUI-based MenuBarExtra for modern approach
struct SecureDeskMenuBarExtra: Scene {
    
    @Environment(\.openWindow) private var openWindow
    
    var body: some Scene {
        MenuBarExtra("SecureDesk", systemImage: "lock.shield.fill") {
            Button("New Item") {
                NSApp.activate(ignoringOtherApps: true)
                NotificationCenter.default.post(name: .newItemRequested, object: nil)
            }
            .keyboardShortcut("n", modifiers: .command)
            
            Button("Refresh") {
                NotificationCenter.default.post(name: .refreshRequested, object: nil)
            }
            .keyboardShortcut("r", modifiers: .command)
            
            Divider()
            
            Menu("Status") {
                Text("Environment: Mock")
                Text("Network: Online")
            }
            
            Divider()
            
            Button("Open SecureDesk") {
                NSApp.activate(ignoringOtherApps: true)
            }
            
            Divider()
            
            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
    }
}

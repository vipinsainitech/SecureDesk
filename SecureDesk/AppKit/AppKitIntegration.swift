//
//  AppKitIntegration.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import SwiftUI
import AppKit

// MARK: - Window Access

/// Provides access to the underlying NSWindow for customization
struct WindowAccessor: NSViewRepresentable {
    
    let callback: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.callback(view.window)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            self.callback(nsView.window)
        }
    }
}

extension View {
    /// Access the underlying NSWindow for customization
    func withWindowAccess(_ callback: @escaping (NSWindow?) -> Void) -> some View {
        self.background(WindowAccessor(callback: callback))
    }
    
    /// Configure window appearance
    func configureWindow(
        minSize: CGSize? = nil,
        titlebarAppearsTransparent: Bool = false,
        titleVisibility: NSWindow.TitleVisibility = .visible
    ) -> some View {
        self.withWindowAccess { window in
            guard let window = window else { return }
            
            if let minSize = minSize {
                window.minSize = minSize
            }
            
            window.titlebarAppearsTransparent = titlebarAppearsTransparent
            window.titleVisibility = titleVisibility
        }
    }
}

// MARK: - Custom Window Toolbar

/// Creates a native macOS toolbar
class AppToolbar: NSToolbar, NSToolbarDelegate {
    
    static let mainToolbarIdentifier = NSToolbar.Identifier("MainToolbar")
    
    private enum ToolbarItemIdentifier: String {
        case search
        case newItem
        case refresh
        case flexibleSpace
        
        var identifier: NSToolbarItem.Identifier {
            NSToolbarItem.Identifier(rawValue)
        }
    }
    
    override init(identifier: NSToolbar.Identifier) {
        super.init(identifier: identifier)
        self.delegate = self
        self.displayMode = .iconAndLabel
        self.allowsUserCustomization = true
        self.autosavesConfiguration = true
    }
    
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            ToolbarItemIdentifier.newItem.identifier,
            .flexibleSpace,
            ToolbarItemIdentifier.search.identifier
        ]
    }
    
    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        [
            ToolbarItemIdentifier.newItem.identifier,
            ToolbarItemIdentifier.refresh.identifier,
            ToolbarItemIdentifier.search.identifier,
            .flexibleSpace,
            .space
        ]
    }
    
    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier, willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        
        switch itemIdentifier.rawValue {
        case ToolbarItemIdentifier.newItem.rawValue:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "New Item"
            item.paletteLabel = "New Item"
            item.toolTip = "Create a new item"
            item.image = NSImage(systemSymbolName: "plus", accessibilityDescription: "New")
            item.target = self
            item.action = #selector(newItemAction)
            return item
            
        case ToolbarItemIdentifier.refresh.rawValue:
            let item = NSToolbarItem(itemIdentifier: itemIdentifier)
            item.label = "Refresh"
            item.paletteLabel = "Refresh"
            item.toolTip = "Refresh items"
            item.image = NSImage(systemSymbolName: "arrow.clockwise", accessibilityDescription: "Refresh")
            item.target = self
            item.action = #selector(refreshAction)
            return item
            
        case ToolbarItemIdentifier.search.rawValue:
            let item = NSSearchToolbarItem(itemIdentifier: itemIdentifier)
            item.searchField.placeholderString = "Search items..."
            return item
            
        default:
            return nil
        }
    }
    
    @objc private func newItemAction() {
        NotificationCenter.default.post(name: .newItemRequested, object: nil)
    }
    
    @objc private func refreshAction() {
        NotificationCenter.default.post(name: .refreshRequested, object: nil)
    }
}

// MARK: - Dock Menu

/// Provides the application's Dock menu
class DockMenuProvider: NSObject {
    
    static let shared = DockMenuProvider()
    
    func createDockMenu() -> NSMenu {
        let menu = NSMenu()
        
        // New Item
        let newItem = NSMenuItem(
            title: "New Item",
            action: #selector(newItemAction),
            keyEquivalent: ""
        )
        newItem.target = self
        menu.addItem(newItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quick Status
        let statusItem = NSMenuItem(title: "Status", action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        
        let statusSubmenu = NSMenu()
        
        let mockModeItem = NSMenuItem(
            title: FeatureFlags.useMockServices ? "Mock Mode Active" : "Live Mode",
            action: nil,
            keyEquivalent: ""
        )
        mockModeItem.isEnabled = false
        statusSubmenu.addItem(mockModeItem)
        
        statusItem.submenu = statusSubmenu
        menu.addItem(statusItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Refresh
        let refreshItem = NSMenuItem(
            title: "Refresh",
            action: #selector(refreshAction),
            keyEquivalent: ""
        )
        refreshItem.target = self
        menu.addItem(refreshItem)
        
        return menu
    }
    
    @objc private func newItemAction() {
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(name: .newItemRequested, object: nil)
    }
    
    @objc private func refreshAction() {
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(name: .refreshRequested, object: nil)
    }
}

// MARK: - App Delegate for Dock Menu

class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        return DockMenuProvider.shared.createDockMenu()
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure main window
        if let window = NSApp.windows.first {
            window.minSize = NSSize(width: 800, height: 600)
            window.title = "SecureDesk"
            
            // Set window appearance
            window.titlebarAppearsTransparent = false
            window.titleVisibility = .visible
            window.toolbarStyle = .unified
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// MARK: - Native File Dialogs

struct NativeFileDialog {
    
    /// Show save panel
    static func showSavePanel(
        title: String = "Save",
        allowedTypes: [String] = ["json"],
        suggestedName: String = "export"
    ) async -> URL? {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let panel = NSSavePanel()
                panel.title = title
                panel.nameFieldStringValue = suggestedName
                panel.allowedContentTypes = allowedTypes.compactMap { 
                    UTType(filenameExtension: $0)
                }
                panel.canCreateDirectories = true
                
                if panel.runModal() == .OK {
                    continuation.resume(returning: panel.url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    /// Show open panel
    static func showOpenPanel(
        title: String = "Open",
        allowedTypes: [String] = ["json"],
        allowsMultiple: Bool = false
    ) async -> [URL] {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let panel = NSOpenPanel()
                panel.title = title
                panel.allowsMultipleSelection = allowsMultiple
                panel.canChooseDirectories = false
                panel.canChooseFiles = true
                panel.allowedContentTypes = allowedTypes.compactMap {
                    UTType(filenameExtension: $0)
                }
                
                if panel.runModal() == .OK {
                    continuation.resume(returning: panel.urls)
                } else {
                    continuation.resume(returning: [])
                }
            }
        }
    }
}

// MARK: - Clipboard Helper

struct Clipboard {
    
    static func copy(_ string: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
    }
    
    static func paste() -> String? {
        NSPasteboard.general.string(forType: .string)
    }
}

// MARK: - System Appearance

struct SystemAppearance {
    
    /// Whether the system is in dark mode
    static var isDarkMode: Bool {
        NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
    }
    
    /// Get current accent color
    static var accentColor: NSColor {
        NSColor.controlAccentColor
    }
    
    /// Force appearance for testing
    static func setAppearance(_ appearance: NSAppearance.Name?) {
        if let name = appearance {
            NSApp.appearance = NSAppearance(named: name)
        } else {
            NSApp.appearance = nil // Use system default
        }
    }
}

// MARK: - Haptic Feedback

struct HapticFeedback {
    
    static func perform(_ pattern: NSHapticFeedbackManager.FeedbackPattern) {
        NSHapticFeedbackManager.defaultPerformer.perform(pattern, performanceTime: .default)
    }
    
    static func success() {
        perform(.generic)
    }
    
    static func error() {
        perform(.levelChange)
    }
}

// MARK: - Required Import for UTType

import UniformTypeIdentifiers

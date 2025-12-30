//
//  EmptyStateView.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import SwiftUI

/// A reusable empty state view
struct EmptyStateView: View {
    
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            
            // Title
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            // Message
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Action button
            if let actionTitle, let action {
                Button(actionTitle) {
                    action()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preset Empty States

extension EmptyStateView {
    /// Empty state for no items
    static func noItems(onCreate: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "tray",
            title: "No Items Yet",
            message: "Create your first item to get started with SecureDesk.",
            actionTitle: onCreate != nil ? "Create Item" : nil,
            action: onCreate
        )
    }
    
    /// Empty state for no search results
    static func noSearchResults(onClear: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "magnifyingglass",
            title: "No Results Found",
            message: "Try adjusting your search or filter criteria.",
            actionTitle: onClear != nil ? "Clear Search" : nil,
            action: onClear
        )
    }
    
    /// Empty state for network offline
    static func offline(onRetry: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "wifi.slash",
            title: "You're Offline",
            message: "Check your internet connection and try again.",
            actionTitle: onRetry != nil ? "Retry" : nil,
            action: onRetry
        )
    }
    
    /// Empty state for not authenticated
    static func notAuthenticated(onLogin: (() -> Void)? = nil) -> EmptyStateView {
        EmptyStateView(
            icon: "person.crop.circle.badge.questionmark",
            title: "Sign In Required",
            message: "Please sign in to access your items.",
            actionTitle: onLogin != nil ? "Sign In" : nil,
            action: onLogin
        )
    }
}

// MARK: - Preview

#Preview("No Items") {
    EmptyStateView.noItems(onCreate: {})
}

#Preview("No Search Results") {
    EmptyStateView.noSearchResults(onClear: {})
}

#Preview("Offline") {
    EmptyStateView.offline(onRetry: {})
}

#Preview("Custom") {
    EmptyStateView(
        icon: "star",
        title: "No Favorites",
        message: "Items you mark as favorites will appear here.",
        actionTitle: nil,
        action: nil
    )
}

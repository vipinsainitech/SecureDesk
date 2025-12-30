//
//  MainNavigationView.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import SwiftUI

/// Navigation destination for sidebar items
enum NavigationDestination: String, CaseIterable, Identifiable {
    case dashboard
    case settings
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .settings: return "Settings"
        }
    }
    
    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2"
        case .settings: return "gear"
        }
    }
}

/// Main navigation view with sidebar
struct MainNavigationView: View {
    
    @Environment(\.appContainer) private var container
    @State private var selectedDestination: NavigationDestination? = .dashboard
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            sidebar
                .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
        } detail: {
            // Detail View
            detailView
        }
        .navigationSplitViewStyle(.balanced)
    }
    
    // MARK: - Sidebar
    
    private var sidebar: some View {
        List(selection: $selectedDestination) {
            Section {
                ForEach(NavigationDestination.allCases) { destination in
                    NavigationLink(value: destination) {
                        Label(destination.title, systemImage: destination.icon)
                    }
                }
            } header: {
                Text("Menu")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Section {
                // App Status
                HStack {
                    Circle()
                        .fill(FeatureFlags.useMockServices ? .orange : .green)
                        .frame(width: 8, height: 8)
                    
                    Text(FeatureFlags.useMockServices ? "Mock Mode" : "Live")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("Status")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.sidebar)
    }
    
    // MARK: - Detail View
    
    @ViewBuilder
    private var detailView: some View {
        switch selectedDestination {
        case .dashboard:
            DashboardView(viewModel: container.makeDashboardViewModel())
        case .settings:
            SettingsView(viewModel: container.makeSettingsViewModel())
        case nil:
            // Default view
            VStack {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 48))
                    .foregroundStyle(.secondary)
                Text("Select an item from the sidebar")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Actions
    
    private func toggleSidebar() {
        withAnimation {
            switch columnVisibility {
            case .all:
                columnVisibility = .detailOnly
            default:
                columnVisibility = .all
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MainNavigationView()
        .environment(\.appContainer, .forPreview())
        .frame(width: 900, height: 600)
}

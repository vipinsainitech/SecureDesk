//
//  OfflineBanner.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import SwiftUI

/// Banner displayed when app is offline
struct OfflineBanner: View {
    
    @Environment(\.networkMonitor) private var networkMonitor
    @State private var isExpanded = false
    
    var body: some View {
        if !networkMonitor.isConnected {
            VStack(spacing: 0) {
                banner
                
                if isExpanded {
                    details
                }
            }
            .animation(.easeInOut(duration: 0.2), value: isExpanded)
        }
    }
    
    private var banner: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.subheadline)
            
            Text("You're offline")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Spacer()
            
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                colors: [.orange.opacity(0.9), .orange],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .foregroundStyle(.white)
    }
    
    private var details: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Working with cached data")
                .font(.caption)
            
            HStack {
                Image(systemName: "clock")
                    .font(.caption2)
                Text("Last sync: \(lastSyncText)")
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
            
            if FeatureFlagManager.shared.isEnabled(.enableOfflineMode) {
                Text("Changes will sync when online")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.orange.opacity(0.1))
    }
    
    private var lastSyncText: String {
        // Placeholder - would read from persistence
        "Recently"
    }
}

// MARK: - Compact Offline Indicator

/// Small indicator for sidebar or status bar
struct OfflineIndicator: View {
    
    @Environment(\.networkMonitor) private var networkMonitor
    
    var body: some View {
        if !networkMonitor.isConnected {
            HStack(spacing: 4) {
                Circle()
                    .fill(.orange)
                    .frame(width: 6, height: 6)
                
                Text("Offline")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Connection Status View

/// Detailed connection status for settings/debug
struct ConnectionStatusView: View {
    
    @Environment(\.networkMonitor) private var networkMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status row
            HStack {
                Image(systemName: networkMonitor.connectionType.icon)
                    .foregroundStyle(networkMonitor.isConnected ? .green : .red)
                
                VStack(alignment: .leading) {
                    Text(networkMonitor.isConnected ? "Connected" : "Disconnected")
                        .font(.headline)
                    
                    Text(networkMonitor.connectionType.displayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Circle()
                    .fill(networkMonitor.isConnected ? .green : .red)
                    .frame(width: 10, height: 10)
            }
            
            // Additional info
            if networkMonitor.isConnected {
                if networkMonitor.isExpensive {
                    Label("Using cellular data", systemImage: "exclamationmark.triangle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
                
                if networkMonitor.isConstrained {
                    Label("Low Data Mode enabled", systemImage: "arrow.down.circle")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Preview

#Preview("Offline Banner") {
    VStack {
        OfflineBanner()
        Spacer()
    }
    .frame(width: 400, height: 300)
}

#Preview("Connection Status") {
    ConnectionStatusView()
        .padding()
        .frame(width: 300)
}

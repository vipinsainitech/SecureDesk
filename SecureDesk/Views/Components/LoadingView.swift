//
//  LoadingView.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import SwiftUI

/// A reusable loading indicator view
struct LoadingView: View {
    
    var message: String = "Loading..."
    var showProgress: Bool = true
    
    var body: some View {
        VStack(spacing: 16) {
            if showProgress {
                ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(.circular)
            }
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

/// A loading overlay that can be placed over other content
struct LoadingOverlay: View {
    
    var isLoading: Bool
    var message: String = "Loading..."
    
    var body: some View {
        if isLoading {
            ZStack {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.2)
                    
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
                .padding(24)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }
}

// MARK: - View Modifier

extension View {
    /// Apply a loading overlay
    func loadingOverlay(isLoading: Bool, message: String = "Loading...") -> some View {
        self.overlay {
            LoadingOverlay(isLoading: isLoading, message: message)
        }
    }
}

// MARK: - Preview

#Preview("Loading View") {
    LoadingView()
}

#Preview("Loading Overlay") {
    Text("Content")
        .frame(width: 400, height: 300)
        .loadingOverlay(isLoading: true)
}

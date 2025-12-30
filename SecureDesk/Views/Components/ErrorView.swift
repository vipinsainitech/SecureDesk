//
//  ErrorView.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import SwiftUI

/// A reusable error display view
struct ErrorView: View {
    
    let title: String
    let message: String
    var retryAction: (() -> Void)?
    var dismissAction: (() -> Void)?
    
    init(
        title: String = "Something went wrong",
        message: String,
        retryAction: (() -> Void)? = nil,
        dismissAction: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.retryAction = retryAction
        self.dismissAction = dismissAction
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            
            // Title
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            
            // Message
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Actions
            HStack(spacing: 12) {
                if let dismissAction {
                    Button("Dismiss") {
                        dismissAction()
                    }
                    .buttonStyle(.bordered)
                }
                
                if let retryAction {
                    Button("Try Again") {
                        retryAction()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(.top, 8)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

/// An inline error banner
struct ErrorBanner: View {
    
    let message: String
    var dismissAction: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)
            
            Spacer()
            
            if let dismissAction {
                Button {
                    dismissAction()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.red.gradient, in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
    }
}

/// A success banner
struct SuccessBanner: View {
    
    let message: String
    var dismissAction: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white)
            
            Spacer()
            
            if let dismissAction {
                Button {
                    dismissAction()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.green.gradient, in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview("Error View") {
    ErrorView(
        message: "Unable to load items. Please check your connection and try again.",
        retryAction: {},
        dismissAction: {}
    )
}

#Preview("Error Banner") {
    VStack {
        ErrorBanner(message: "Failed to save changes", dismissAction: {})
        Spacer()
    }
    .frame(width: 400, height: 200)
}

#Preview("Success Banner") {
    VStack {
        SuccessBanner(message: "Profile updated successfully", dismissAction: {})
        Spacer()
    }
    .frame(width: 400, height: 200)
}

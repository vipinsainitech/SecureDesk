//
//  ErrorSheet.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import SwiftUI

/// Sheet displaying detailed error information with actions
struct ErrorSheet: View {
    
    let error: AppError
    let onRetry: (() -> Void)?
    let onDismiss: () -> Void
    
    init(
        error: AppError,
        onRetry: (() -> Void)? = nil,
        onDismiss: @escaping () -> Void
    ) {
        self.error = error
        self.onRetry = onRetry
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: error.category.icon)
                .font(.system(size: 48))
                .foregroundStyle(iconColor)
            
            // Title & Message
            VStack(spacing: 8) {
                Text(error.category.rawValue + " Error")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(error.userMessage)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Suggested action
            if let suggestion = error.suggestedAction {
                HStack(spacing: 6) {
                    Image(systemName: "lightbulb")
                        .font(.caption)
                    Text(suggestion)
                        .font(.caption)
                }
                .foregroundStyle(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(.blue.opacity(0.1), in: Capsule())
            }
            
            // Debug info (DEBUG only)
            #if DEBUG
            if FeatureFlagManager.shared.isVerboseLoggingEnabled {
                Text(error.debugInfo)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .padding()
                    .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 4))
                    .textSelection(.enabled)
            }
            #endif
            
            // Actions
            HStack(spacing: 12) {
                Button("Dismiss") {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                
                if let onRetry = onRetry, error.canRetry {
                    Button("Try Again") {
                        onRetry()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(32)
        .frame(width: 400)
    }
    
    private var iconColor: Color {
        switch error.category {
        case .network: return .orange
        case .authentication: return .red
        case .data, .persistence: return .purple
        case .validation: return .yellow
        case .server: return .red
        case .unknown: return .gray
        }
    }
}

// MARK: - Inline Error View

/// Compact error display for inline use
struct InlineErrorView: View {
    
    let error: AppError
    var onRetry: (() -> Void)?
    var onDismiss: (() -> Void)?
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: error.category.icon)
                .foregroundStyle(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(error.userMessage)
                    .font(.subheadline)
                    .foregroundStyle(.white)
                
                if let suggestion = error.suggestedAction {
                    Text(suggestion)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if let onRetry = onRetry, error.canRetry {
                    Button("Retry") {
                        onRetry()
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                }
                
                if let onDismiss = onDismiss {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(.red.gradient, in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal)
    }
}

// MARK: - View Modifier

extension View {
    /// Present an error sheet
    func errorSheet(
        error: Binding<AppError?>,
        onRetry: (() -> Void)? = nil
    ) -> some View {
        self.sheet(item: error) { err in
            ErrorSheet(
                error: err,
                onRetry: onRetry,
                onDismiss: { error.wrappedValue = nil }
            )
        }
    }
}

// MARK: - AppError Identifiable

extension AppError: Identifiable {
    var id: String {
        "\(category.rawValue)_\(userMessage.hashValue)"
    }
}

// MARK: - Preview

#Preview("Error Sheet") {
    ErrorSheet(
        error: .networkUnavailable,
        onRetry: {},
        onDismiss: {}
    )
}

#Preview("Inline Error") {
    VStack {
        InlineErrorView(
            error: .sessionExpired,
            onRetry: {},
            onDismiss: {}
        )
        Spacer()
    }
    .frame(width: 500, height: 300)
}

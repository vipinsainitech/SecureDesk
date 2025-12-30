//
//  LoginView.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import SwiftUI

/// Login screen with email/password authentication
struct LoginView: View {
    
    @State private var viewModel: LoginViewModel
    @FocusState private var focusedField: Field?
    
    private enum Field: Hashable {
        case email
        case password
    }
    
    init(viewModel: LoginViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo & Title
            headerSection
            
            Spacer()
                .frame(height: 40)
            
            // Login Form
            formSection
            
            Spacer()
            
            // Footer
            footerSection
        }
        .frame(minWidth: 400, minHeight: 500)
        .background(backgroundGradient)
        .onSubmit {
            handleSubmit()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            // App Icon
            Image(systemName: "lock.shield.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue.gradient)
                .symbolEffect(.pulse, options: .repeating)
            
            // Title
            Text("SecureDesk")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Subtitle
            Text("Sign in to your account")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Form Section
    
    private var formSection: some View {
        VStack(spacing: 20) {
            // Error Banner
            if let error = viewModel.errorMessage {
                ErrorBanner(message: error) {
                    viewModel.dismissError()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            // Form Fields
            VStack(spacing: 16) {
                // Email Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    TextField("you@example.com", text: $viewModel.email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .focused($focusedField, equals: .email)
                        .disabled(viewModel.isLoading)
                }
                
                // Password Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    SecureField("Enter your password", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .disabled(viewModel.isLoading)
                }
            }
            .padding(.horizontal, 40)
            
            // Login Button
            Button {
                Task {
                    await viewModel.login()
                }
            } label: {
                HStack(spacing: 8) {
                    if viewModel.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(.circular)
                    }
                    Text(viewModel.isLoading ? "Signing In..." : "Sign In")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 36)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.canSubmit)
            .padding(.horizontal, 40)
            .padding(.top, 8)
            
            // Demo Hint
            if FeatureFlags.useMockServices {
                Text("Demo mode: Use any email/password to sign in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.errorMessage)
    }
    
    // MARK: - Footer Section
    
    private var footerSection: some View {
        VStack(spacing: 8) {
            Text("SecureDesk v1.0")
                .font(.caption2)
                .foregroundStyle(.tertiary)
            
            if FeatureFlags.useMockServices {
                Text("Mock Services Enabled")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(nsColor: .windowBackgroundColor),
                Color(nsColor: .windowBackgroundColor).opacity(0.95)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Actions
    
    private func handleSubmit() {
        switch focusedField {
        case .email:
            focusedField = .password
        case .password:
            if viewModel.canSubmit {
                Task {
                    await viewModel.login()
                }
            }
        case nil:
            break
        }
    }
}

// MARK: - Preview

#Preview {
    LoginView(viewModel: .preview)
}

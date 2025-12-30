//
//  SettingsView.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import SwiftUI

/// Settings screen with user profile and app preferences
struct SettingsView: View {
    
    @State private var viewModel: SettingsViewModel
    @State private var showingLogoutAlert = false
    
    init(viewModel: SettingsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Messages
                messagesSection
                
                // Profile Section
                profileSection
                
                // Preferences Section
                preferencesSection
                
                // App Info Section
                appInfoSection
                
                // Actions Section
                actionsSection
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor).opacity(0.5))
        .task {
            await viewModel.loadUser()
        }
        .alert("Sign Out", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                Task {
                    await viewModel.logout()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    // MARK: - Messages Section
    
    @ViewBuilder
    private var messagesSection: some View {
        if let error = viewModel.errorMessage {
            ErrorBanner(message: error) {
                viewModel.dismissMessages()
            }
        }
        
        if let success = viewModel.successMessage {
            SuccessBanner(message: success) {
                viewModel.dismissMessages()
            }
        }
    }
    
    // MARK: - Profile Section
    
    private var profileSection: some View {
        SettingsSection(title: "Profile") {
            if viewModel.isLoading && viewModel.currentUser == nil {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if let user = viewModel.currentUser {
                VStack(spacing: 16) {
                    // Avatar
                    HStack {
                        AsyncImage(url: user.avatarURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 4) {
                            if viewModel.isEditingProfile {
                                TextField("Name", text: $viewModel.editedName)
                                    .textFieldStyle(.roundedBorder)
                            } else {
                                Text(user.name)
                                    .font(.headline)
                            }
                            
                            HStack(spacing: 4) {
                                Text(user.role.displayName)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(.blue.opacity(0.1), in: Capsule())
                                    .foregroundStyle(.blue)
                                
                                if user.isEmailVerified {
                                    Label("Verified", systemImage: "checkmark.seal.fill")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                }
                            }
                        }
                        
                        Spacer()
                        
                        if viewModel.isEditingProfile {
                            HStack(spacing: 8) {
                                Button("Cancel") {
                                    viewModel.cancelEditing()
                                }
                                .buttonStyle(.bordered)
                                
                                Button("Save") {
                                    Task {
                                        await viewModel.saveProfile()
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(!viewModel.canSaveProfile)
                            }
                        } else {
                            Button("Edit") {
                                viewModel.startEditing()
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    
                    Divider()
                    
                    // Email
                    LabeledContent("Email") {
                        if viewModel.isEditingProfile {
                            TextField("Email", text: $viewModel.editedEmail)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 250)
                        } else {
                            Text(user.email)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Member Since
                    LabeledContent("Member Since") {
                        Text(user.createdAt, style: .date)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    // MARK: - Preferences Section
    
    private var preferencesSection: some View {
        SettingsSection(title: "Preferences") {
            VStack(spacing: 12) {
                #if DEBUG
                Toggle("Use Mock Services", isOn: $viewModel.useMockServices)
                    .toggleStyle(.switch)
                
                Text("When enabled, the app uses mock data instead of real API calls.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                #endif
            }
        }
    }
    
    // MARK: - App Info Section
    
    private var appInfoSection: some View {
        SettingsSection(title: "About") {
            VStack(spacing: 8) {
                LabeledContent("Version") {
                    Text(viewModel.appVersion)
                        .foregroundStyle(.secondary)
                }
                
                LabeledContent("Build") {
                    Text(viewModel.buildConfiguration)
                        .foregroundStyle(.secondary)
                }
                
                if FeatureFlags.useMockServices {
                    LabeledContent("Environment") {
                        Text("Development (Mock)")
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        SettingsSection(title: "Account") {
            Button(role: .destructive) {
                showingLogoutAlert = true
            } label: {
                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }
}

// MARK: - Settings Section

struct SettingsSection<Content: View>: View {
    
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                content
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

// MARK: - Preview

#Preview {
    SettingsView(viewModel: .preview)
        .frame(width: 600, height: 700)
}

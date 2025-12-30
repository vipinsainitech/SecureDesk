//
//  User.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation

/// Represents a user account in the system
struct User: Codable, Identifiable, Equatable, Sendable {
    
    /// Unique identifier for the user
    let id: String
    
    /// User's email address
    let email: String
    
    /// User's display name
    let name: String
    
    /// URL to the user's avatar image
    let avatarURL: URL?
    
    /// When the user account was created
    let createdAt: Date
    
    /// User's role in the system
    let role: UserRole
    
    /// Whether the user's email has been verified
    let isEmailVerified: Bool
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case avatarURL = "avatar_url"
        case createdAt = "created_at"
        case role
        case isEmailVerified = "is_email_verified"
    }
}

// MARK: - User Role

enum UserRole: String, Codable, Sendable {
    case admin
    case member
    case viewer
    
    var displayName: String {
        switch self {
        case .admin: return "Administrator"
        case .member: return "Member"
        case .viewer: return "Viewer"
        }
    }
}

// MARK: - Mock Data

extension User {
    /// Sample user for previews and testing
    static let preview = User(
        id: "usr_preview_001",
        email: "john.doe@example.com",
        name: "John Doe",
        avatarURL: URL(string: "https://api.dicebear.com/7.x/avataaars/svg?seed=john"),
        createdAt: Date().addingTimeInterval(-86400 * 30), // 30 days ago
        role: .admin,
        isEmailVerified: true
    )
    
    /// Array of sample users for testing
    static let previewList: [User] = [
        .preview,
        User(
            id: "usr_preview_002",
            email: "jane.smith@example.com",
            name: "Jane Smith",
            avatarURL: URL(string: "https://api.dicebear.com/7.x/avataaars/svg?seed=jane"),
            createdAt: Date().addingTimeInterval(-86400 * 15),
            role: .member,
            isEmailVerified: true
        ),
        User(
            id: "usr_preview_003",
            email: "bob.wilson@example.com",
            name: "Bob Wilson",
            avatarURL: nil,
            createdAt: Date().addingTimeInterval(-86400 * 7),
            role: .viewer,
            isEmailVerified: false
        )
    ]
}

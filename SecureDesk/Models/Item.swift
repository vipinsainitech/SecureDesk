//
//  Item.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation

/// Represents an item/task in the system
struct Item: Codable, Identifiable, Equatable, Sendable {
    
    /// Unique identifier for the item
    let id: String
    
    /// Item title
    let title: String
    
    /// Detailed description
    let description: String
    
    /// Current status
    var status: ItemStatus
    
    /// Priority level
    let priority: ItemPriority
    
    /// When the item was created
    let createdAt: Date
    
    /// When the item was last updated
    var updatedAt: Date
    
    /// ID of the user who created this item
    let createdBy: String
    
    /// Optional due date
    let dueDate: Date?
    
    /// Tags for categorization
    let tags: [String]
    
    // MARK: - Coding Keys
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case status
        case priority
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case createdBy = "created_by"
        case dueDate = "due_date"
        case tags
    }
}

// MARK: - Item Status

enum ItemStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case inProgress = "in_progress"
    case completed
    case archived
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        case .archived: return "Archived"
        }
    }
    
    var iconName: String {
        switch self {
        case .pending: return "circle"
        case .inProgress: return "circle.lefthalf.filled"
        case .completed: return "checkmark.circle.fill"
        case .archived: return "archivebox"
        }
    }
    
    var color: String {
        switch self {
        case .pending: return "gray"
        case .inProgress: return "blue"
        case .completed: return "green"
        case .archived: return "secondary"
        }
    }
}

// MARK: - Item Priority

enum ItemPriority: String, Codable, CaseIterable, Sendable {
    case low
    case medium
    case high
    case urgent
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        case .urgent: return "Urgent"
        }
    }
    
    var iconName: String {
        switch self {
        case .low: return "arrow.down"
        case .medium: return "minus"
        case .high: return "arrow.up"
        case .urgent: return "exclamationmark.triangle.fill"
        }
    }
}

// MARK: - Mock Data

extension Item {
    /// Sample item for previews and testing
    static let preview = Item(
        id: "item_preview_001",
        title: "Review Q4 Reports",
        description: "Review and approve the quarterly financial reports before the board meeting.",
        status: .inProgress,
        priority: .high,
        createdAt: Date().addingTimeInterval(-86400 * 3),
        updatedAt: Date().addingTimeInterval(-3600),
        createdBy: "usr_preview_001",
        dueDate: Date().addingTimeInterval(86400 * 2),
        tags: ["finance", "quarterly", "review"]
    )
    
    /// Array of sample items for testing
    static let previewList: [Item] = [
        .preview,
        Item(
            id: "item_preview_002",
            title: "Update Security Policies",
            description: "Update the security policies document with new compliance requirements.",
            status: .pending,
            priority: .urgent,
            createdAt: Date().addingTimeInterval(-86400 * 7),
            updatedAt: Date().addingTimeInterval(-86400),
            createdBy: "usr_preview_001",
            dueDate: Date().addingTimeInterval(86400),
            tags: ["security", "compliance"]
        ),
        Item(
            id: "item_preview_003",
            title: "Team Onboarding Session",
            description: "Prepare and conduct onboarding session for new team members.",
            status: .completed,
            priority: .medium,
            createdAt: Date().addingTimeInterval(-86400 * 14),
            updatedAt: Date().addingTimeInterval(-86400 * 2),
            createdBy: "usr_preview_002",
            dueDate: nil,
            tags: ["hr", "onboarding"]
        ),
        Item(
            id: "item_preview_004",
            title: "Database Migration Planning",
            description: "Plan the migration from PostgreSQL 14 to 16 with minimal downtime.",
            status: .inProgress,
            priority: .high,
            createdAt: Date().addingTimeInterval(-86400 * 5),
            updatedAt: Date().addingTimeInterval(-7200),
            createdBy: "usr_preview_001",
            dueDate: Date().addingTimeInterval(86400 * 7),
            tags: ["database", "infrastructure"]
        ),
        Item(
            id: "item_preview_005",
            title: "Update Documentation",
            description: "Update the API documentation with new endpoints.",
            status: .pending,
            priority: .low,
            createdAt: Date().addingTimeInterval(-86400),
            updatedAt: Date().addingTimeInterval(-3600 * 2),
            createdBy: "usr_preview_003",
            dueDate: Date().addingTimeInterval(86400 * 14),
            tags: ["documentation", "api"]
        )
    ]
}

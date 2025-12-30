//
//  ItemServiceProtocol.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation

/// Protocol defining item/task operations
protocol ItemServiceProtocol: Sendable {
    
    /// Fetch all items for the current user
    /// - Returns: Array of items
    /// - Throws: ItemError on failure
    func fetchItems() async throws -> [Item]
    
    /// Fetch items with optional filtering
    /// - Parameter filter: Optional filter criteria
    /// - Returns: Filtered array of items
    /// - Throws: ItemError on failure
    func fetchItems(filter: ItemFilter?) async throws -> [Item]
    
    /// Get a specific item by ID
    /// - Parameter id: Item's unique identifier
    /// - Returns: Item details
    /// - Throws: ItemError on failure
    func getItem(byId id: String) async throws -> Item
    
    /// Create a new item
    /// - Parameter item: Item to create
    /// - Returns: Created item with server-assigned ID
    /// - Throws: ItemError on failure
    func createItem(_ item: Item) async throws -> Item
    
    /// Update an existing item
    /// - Parameter item: Item with updated values
    /// - Returns: Updated item
    /// - Throws: ItemError on failure
    func updateItem(_ item: Item) async throws -> Item
    
    /// Delete an item
    /// - Parameter id: ID of item to delete
    /// - Throws: ItemError on failure
    func deleteItem(id: String) async throws
    
    /// Update item status
    /// - Parameters:
    ///   - id: Item ID
    ///   - status: New status
    /// - Returns: Updated item
    /// - Throws: ItemError on failure
    func updateStatus(id: String, status: ItemStatus) async throws -> Item
}

// MARK: - Item Filter

/// Filter criteria for fetching items
struct ItemFilter: Sendable {
    var status: ItemStatus?
    var priority: ItemPriority?
    var tags: [String]?
    var searchQuery: String?
    var createdAfter: Date?
    var createdBefore: Date?
    
    init(
        status: ItemStatus? = nil,
        priority: ItemPriority? = nil,
        tags: [String]? = nil,
        searchQuery: String? = nil,
        createdAfter: Date? = nil,
        createdBefore: Date? = nil
    ) {
        self.status = status
        self.priority = priority
        self.tags = tags
        self.searchQuery = searchQuery
        self.createdAfter = createdAfter
        self.createdBefore = createdBefore
    }
}

// MARK: - Item Errors

/// Errors that can occur during item operations
enum ItemError: LocalizedError, Equatable {
    case notFound
    case unauthorized
    case validationError(String)
    case networkError(String)
    case serverError(String)
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .notFound:
            return "Item not found"
        case .unauthorized:
            return "You don't have permission to access this item"
        case .validationError(let message):
            return "Validation error: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

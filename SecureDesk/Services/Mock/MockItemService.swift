//
//  MockItemService.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation

/// Mock implementation of ItemServiceProtocol for development and testing
actor MockItemService: ItemServiceProtocol {
    
    // MARK: - Mock Configuration
    
    /// Simulated network delay
    var networkDelay: TimeInterval {
        FeatureFlags.mockNetworkDelay
    }
    
    /// Whether to simulate network errors
    var shouldSimulateError = false
    
    // MARK: - Mock Data
    
    private var mockItems: [Item] = Item.previewList
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - ItemServiceProtocol
    
    func fetchItems() async throws -> [Item] {
        try await fetchItems(filter: nil)
    }
    
    func fetchItems(filter: ItemFilter?) async throws -> [Item] {
        try await Task.sleep(for: .seconds(networkDelay))
        
        if shouldSimulateError {
            throw ItemError.networkError("Simulated network error")
        }
        
        var result = mockItems
        
        if let filter = filter {
            // Apply status filter
            if let status = filter.status {
                result = result.filter { $0.status == status }
            }
            
            // Apply priority filter
            if let priority = filter.priority {
                result = result.filter { $0.priority == priority }
            }
            
            // Apply tag filter
            if let tags = filter.tags, !tags.isEmpty {
                result = result.filter { item in
                    !Set(item.tags).isDisjoint(with: Set(tags))
                }
            }
            
            // Apply search query
            if let query = filter.searchQuery, !query.isEmpty {
                let lowercasedQuery = query.lowercased()
                result = result.filter { item in
                    item.title.lowercased().contains(lowercasedQuery) ||
                    item.description.lowercased().contains(lowercasedQuery)
                }
            }
            
            // Apply date filters
            if let createdAfter = filter.createdAfter {
                result = result.filter { $0.createdAt >= createdAfter }
            }
            
            if let createdBefore = filter.createdBefore {
                result = result.filter { $0.createdAt <= createdBefore }
            }
        }
        
        // Sort by creation date (newest first)
        result.sort { $0.createdAt > $1.createdAt }
        
        return result
    }
    
    func getItem(byId id: String) async throws -> Item {
        try await Task.sleep(for: .seconds(networkDelay))
        
        if shouldSimulateError {
            throw ItemError.networkError("Simulated network error")
        }
        
        guard let item = mockItems.first(where: { $0.id == id }) else {
            throw ItemError.notFound
        }
        
        return item
    }
    
    func createItem(_ item: Item) async throws -> Item {
        try await Task.sleep(for: .seconds(networkDelay))
        
        if shouldSimulateError {
            throw ItemError.networkError("Simulated network error")
        }
        
        // Validate
        guard !item.title.isEmpty else {
            throw ItemError.validationError("Title cannot be empty")
        }
        
        // Create new item with generated ID
        let newItem = Item(
            id: "item_\(UUID().uuidString.prefix(8))",
            title: item.title,
            description: item.description,
            status: item.status,
            priority: item.priority,
            createdAt: Date(),
            updatedAt: Date(),
            createdBy: item.createdBy,
            dueDate: item.dueDate,
            tags: item.tags
        )
        
        mockItems.insert(newItem, at: 0)
        
        if FeatureFlags.enableVerboseLogging {
            print("[MockItemService] Created item: \(newItem.title)")
        }
        
        return newItem
    }
    
    func updateItem(_ item: Item) async throws -> Item {
        try await Task.sleep(for: .seconds(networkDelay))
        
        if shouldSimulateError {
            throw ItemError.networkError("Simulated network error")
        }
        
        guard let index = mockItems.firstIndex(where: { $0.id == item.id }) else {
            throw ItemError.notFound
        }
        
        // Validate
        guard !item.title.isEmpty else {
            throw ItemError.validationError("Title cannot be empty")
        }
        
        // Update with new timestamp
        var updatedItem = item
        updatedItem.updatedAt = Date()
        
        mockItems[index] = updatedItem
        
        if FeatureFlags.enableVerboseLogging {
            print("[MockItemService] Updated item: \(updatedItem.title)")
        }
        
        return updatedItem
    }
    
    func deleteItem(id: String) async throws {
        try await Task.sleep(for: .seconds(networkDelay))
        
        if shouldSimulateError {
            throw ItemError.networkError("Simulated network error")
        }
        
        guard let index = mockItems.firstIndex(where: { $0.id == id }) else {
            throw ItemError.notFound
        }
        
        let deletedItem = mockItems.remove(at: index)
        
        if FeatureFlags.enableVerboseLogging {
            print("[MockItemService] Deleted item: \(deletedItem.title)")
        }
    }
    
    func updateStatus(id: String, status: ItemStatus) async throws -> Item {
        try await Task.sleep(for: .seconds(networkDelay))
        
        if shouldSimulateError {
            throw ItemError.networkError("Simulated network error")
        }
        
        guard let index = mockItems.firstIndex(where: { $0.id == id }) else {
            throw ItemError.notFound
        }
        
        var item = mockItems[index]
        item.status = status
        item.updatedAt = Date()
        
        mockItems[index] = item
        
        if FeatureFlags.enableVerboseLogging {
            print("[MockItemService] Updated status for \(item.title) to \(status.displayName)")
        }
        
        return item
    }
    
    // MARK: - Testing Helpers
    
    #if DEBUG
    /// Reset to initial mock data
    func reset() {
        mockItems = Item.previewList
    }
    
    /// Add a mock item for testing
    func addMockItem(_ item: Item) {
        mockItems.append(item)
    }
    #endif
}

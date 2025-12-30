//
//  DashboardViewModel.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation
import SwiftUI

/// View model for the dashboard screen
@MainActor
@Observable
final class DashboardViewModel {
    
    // MARK: - Published Properties
    
    var items: [Item] = []
    var currentUser: User?
    var isLoading = false
    var errorMessage: String?
    var selectedFilter: ItemStatus?
    var searchQuery = ""
    
    // MARK: - Computed Properties
    
    var filteredItems: [Item] {
        var result = items
        
        // Apply status filter
        if let status = selectedFilter {
            result = result.filter { $0.status == status }
        }
        
        // Apply search
        if !searchQuery.isEmpty {
            let query = searchQuery.lowercased()
            result = result.filter { item in
                item.title.lowercased().contains(query) ||
                item.description.lowercased().contains(query) ||
                item.tags.contains { $0.lowercased().contains(query) }
            }
        }
        
        return result
    }
    
    var itemCounts: [ItemStatus: Int] {
        Dictionary(grouping: items, by: \.status)
            .mapValues { $0.count }
    }
    
    var isEmpty: Bool {
        items.isEmpty && !isLoading
    }
    
    var hasError: Bool {
        errorMessage != nil
    }
    
    // MARK: - Dependencies
    
    private let itemService: any ItemServiceProtocol
    private let userService: any UserServiceProtocol
    
    // MARK: - Initialization
    
    init(itemService: any ItemServiceProtocol, userService: any UserServiceProtocol) {
        self.itemService = itemService
        self.userService = userService
    }
    
    // MARK: - Actions
    
    /// Load all data
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        // Load items and user concurrently
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.loadItems()
            }
            group.addTask {
                await self.loadUser()
            }
        }
        
        isLoading = false
    }
    
    /// Refresh items only
    func refreshItems() async {
        await loadItems()
    }
    
    /// Update item status
    func updateStatus(for item: Item, to status: ItemStatus) async {
        do {
            let updated = try await itemService.updateStatus(id: item.id, status: status)
            
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index] = updated
            }
        } catch {
            errorMessage = "Failed to update item status"
        }
    }
    
    /// Create a new item
    func createItem(data: ItemCreationData) async {
        do {
            // Get current user ID (fallback to default if not available)
            let userId = currentUser?.id ?? "usr_unknown"
            
            // Create item from data
            let newItem = Item(
                id: UUID().uuidString, // Will be replaced by server
                title: data.title,
                description: data.description,
                status: .pending,
                priority: data.priority,
                createdAt: Date(),
                updatedAt: Date(),
                createdBy: userId,
                dueDate: data.dueDate,
                tags: data.tags
            )
            
            let created = try await itemService.createItem(newItem)
            items.insert(created, at: 0) // Add to beginning of list
        } catch let error as ItemError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to create item"
        }
    }
    
    /// Update an existing item
    func updateItem(_ item: Item, with data: ItemEditData) async {
        do {
            let updatedItem = Item(
                id: item.id,
                title: data.title,
                description: data.description,
                status: data.status,
                priority: data.priority,
                createdAt: item.createdAt,
                updatedAt: Date(),
                createdBy: item.createdBy,
                dueDate: data.dueDate,
                tags: data.tags
            )
            
            let saved = try await itemService.updateItem(updatedItem)
            
            if let index = items.firstIndex(where: { $0.id == item.id }) {
                items[index] = saved
            }
        } catch let error as ItemError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to update item"
        }
    }
    
    /// Delete an item
    func deleteItem(_ item: Item) async {
        do {
            try await itemService.deleteItem(id: item.id)
            items.removeAll { $0.id == item.id }
        } catch {
            errorMessage = "Failed to delete item"
        }
    }
    
    /// Clear filter
    func clearFilter() {
        selectedFilter = nil
        searchQuery = ""
    }
    
    /// Dismiss error
    func dismissError() {
        errorMessage = nil
    }
    
    // MARK: - Private Methods
    
    private func loadItems() async {
        do {
            items = try await itemService.fetchItems()
        } catch let error as ItemError {
            errorMessage = error.localizedDescription
        } catch {
            errorMessage = "Failed to load items"
        }
    }
    
    private func loadUser() async {
        do {
            currentUser = try await userService.getCurrentUser()
        } catch {
            // Non-critical, don't show error
            if FeatureFlags.enableVerboseLogging {
                print("[DashboardViewModel] Failed to load user: \(error)")
            }
        }
    }
}

// MARK: - Preview

extension DashboardViewModel {
    /// Preview instance with mock data
    static var preview: DashboardViewModel {
        let vm = DashboardViewModel(
            itemService: MockItemService(),
            userService: MockUserService()
        )
        vm.items = Item.previewList
        vm.currentUser = User.preview
        return vm
    }
}

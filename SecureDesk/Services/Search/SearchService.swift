//
//  SearchService.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation
import Combine

/// Service for searching and filtering items
/// Optimized for large datasets with debouncing
actor SearchService {
    
    // MARK: - Search Configuration
    
    struct Configuration {
        var debounceInterval: TimeInterval = 0.3
        var minQueryLength: Int = 2
        var maxResults: Int = 100
        var enableFuzzyMatching: Bool = true
    }
    
    private var configuration: Configuration
    
    // MARK: - Initialization
    
    init(configuration: Configuration = .init()) {
        self.configuration = configuration
    }
    
    // MARK: - Search
    
    /// Search items by query
    /// - Parameters:
    ///   - query: Search query string
    ///   - items: Items to search in
    /// - Returns: Matching items sorted by relevance
    func search(_ query: String, in items: [Item]) async -> [Item] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        guard trimmedQuery.count >= configuration.minQueryLength else {
            return items
        }
        
        // Score each item
        var scoredItems: [(item: Item, score: Double)] = []
        
        for item in items {
            let score = calculateScore(for: item, query: trimmedQuery)
            if score > 0 {
                scoredItems.append((item, score))
            }
        }
        
        // Sort by score descending
        scoredItems.sort { $0.score > $1.score }
        
        // Return top results
        return Array(scoredItems.prefix(configuration.maxResults).map(\.item))
    }
    
    /// Filter items by criteria
    /// - Parameters:
    ///   - items: Items to filter
    ///   - criteria: Filter criteria
    /// - Returns: Filtered items
    func filter(_ items: [Item], by criteria: FilterCriteria) -> [Item] {
        items.filter { item in
            // Status filter
            if let status = criteria.status, item.status != status {
                return false
            }
            
            // Priority filter
            if let priority = criteria.priority, item.priority != priority {
                return false
            }
            
            // Tags filter
            if let tags = criteria.tags, !tags.isEmpty {
                let itemTags = Set(item.tags.map { $0.lowercased() })
                let filterTags = Set(tags.map { $0.lowercased() })
                if itemTags.isDisjoint(with: filterTags) {
                    return false
                }
            }
            
            // Date range filter
            if let after = criteria.createdAfter, item.createdAt < after {
                return false
            }
            
            if let before = criteria.createdBefore, item.createdAt > before {
                return false
            }
            
            return true
        }
    }
    
    /// Sort items
    /// - Parameters:
    ///   - items: Items to sort
    ///   - option: Sort option
    /// - Returns: Sorted items
    func sort(_ items: [Item], by option: SortOption) -> [Item] {
        switch option {
        case .createdAtDescending:
            return items.sorted { $0.createdAt > $1.createdAt }
        case .createdAtAscending:
            return items.sorted { $0.createdAt < $1.createdAt }
        case .updatedAtDescending:
            return items.sorted { $0.updatedAt > $1.updatedAt }
        case .updatedAtAscending:
            return items.sorted { $0.updatedAt < $1.updatedAt }
        case .titleAscending:
            return items.sorted { $0.title.lowercased() < $1.title.lowercased() }
        case .titleDescending:
            return items.sorted { $0.title.lowercased() > $1.title.lowercased() }
        case .priorityDescending:
            return items.sorted { $0.priority.sortOrder > $1.priority.sortOrder }
        case .priorityAscending:
            return items.sorted { $0.priority.sortOrder < $1.priority.sortOrder }
        case .dueDateAscending:
            return items.sorted {
                guard let date1 = $0.dueDate else { return false }
                guard let date2 = $1.dueDate else { return true }
                return date1 < date2
            }
        case .dueDateDescending:
            return items.sorted {
                guard let date1 = $0.dueDate else { return false }
                guard let date2 = $1.dueDate else { return true }
                return date1 > date2
            }
        }
    }
    
    // MARK: - Combined Operations
    
    /// Search, filter, and sort items
    func searchAndFilter(
        query: String?,
        items: [Item],
        criteria: FilterCriteria?,
        sortBy: SortOption = .createdAtDescending
    ) async -> [Item] {
        var result = items
        
        // Apply search
        if let query = query, !query.isEmpty {
            result = await search(query, in: result)
        }
        
        // Apply filter
        if let criteria = criteria {
            result = filter(result, by: criteria)
        }
        
        // Apply sort (only if no search, since search already sorts by relevance)
        if query == nil || query?.isEmpty == true {
            result = sort(result, by: sortBy)
        }
        
        return result
    }
    
    // MARK: - Private Methods
    
    private func calculateScore(for item: Item, query: String) -> Double {
        var score = 0.0
        
        // Title match (highest weight)
        if item.title.lowercased().contains(query) {
            score += 10.0
            
            // Exact match bonus
            if item.title.lowercased() == query {
                score += 5.0
            }
            
            // Starts with bonus
            if item.title.lowercased().hasPrefix(query) {
                score += 3.0
            }
        }
        
        // Description match
        if item.description.lowercased().contains(query) {
            score += 5.0
        }
        
        // Tag match
        for tag in item.tags {
            if tag.lowercased().contains(query) {
                score += 3.0
            }
            if tag.lowercased() == query {
                score += 2.0
            }
        }
        
        // Fuzzy matching (if enabled)
        if configuration.enableFuzzyMatching && score == 0 {
            if fuzzyMatch(item.title.lowercased(), query: query) {
                score += 2.0
            }
        }
        
        return score
    }
    
    private func fuzzyMatch(_ text: String, query: String) -> Bool {
        // Simple fuzzy match: all characters in query appear in order in text
        var queryIndex = query.startIndex
        
        for char in text {
            if queryIndex == query.endIndex {
                return true
            }
            if char == query[queryIndex] {
                queryIndex = query.index(after: queryIndex)
            }
        }
        
        return queryIndex == query.endIndex
    }
}

// MARK: - Filter Criteria

struct FilterCriteria: Sendable {
    var status: ItemStatus?
    var priority: ItemPriority?
    var tags: [String]?
    var createdAfter: Date?
    var createdBefore: Date?
    
    static let empty = FilterCriteria()
}

// MARK: - Sort Option

enum SortOption: String, CaseIterable, Identifiable, Sendable {
    case createdAtDescending = "Newest First"
    case createdAtAscending = "Oldest First"
    case updatedAtDescending = "Recently Updated"
    case updatedAtAscending = "Least Recently Updated"
    case titleAscending = "Title A-Z"
    case titleDescending = "Title Z-A"
    case priorityDescending = "Highest Priority"
    case priorityAscending = "Lowest Priority"
    case dueDateAscending = "Due Soon"
    case dueDateDescending = "Due Later"
    
    var id: String { rawValue }
}

// MARK: - Priority Sort Order

extension ItemPriority {
    var sortOrder: Int {
        switch self {
        case .low: return 0
        case .medium: return 1
        case .high: return 2
        case .urgent: return 3
        }
    }
}

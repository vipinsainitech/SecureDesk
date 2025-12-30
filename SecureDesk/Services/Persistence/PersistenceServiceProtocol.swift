//
//  PersistenceServiceProtocol.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation

/// Protocol defining local persistence operations
/// Implementations can use FileManager, CoreData, SQLite, etc.
protocol PersistenceServiceProtocol: Sendable {
    
    /// Save a Codable object
    /// - Parameters:
    ///   - object: The object to save
    ///   - key: Unique key for retrieval
    func save<T: Codable & Sendable>(_ object: T, forKey key: String) async throws
    
    /// Load a Codable object
    /// - Parameters:
    ///   - type: The type to decode
    ///   - key: Key used when saving
    /// - Returns: Decoded object or nil if not found
    func load<T: Codable & Sendable>(_ type: T.Type, forKey key: String) async throws -> T?
    
    /// Delete an object by key
    /// - Parameter key: Key of item to delete
    func delete(forKey key: String) async throws
    
    /// Check if an object exists
    /// - Parameter key: Key to check
    /// - Returns: Whether item exists
    func exists(forKey key: String) async -> Bool
    
    /// Get all stored keys
    /// - Returns: Array of all keys
    func allKeys() async throws -> [String]
    
    /// Clear all stored data
    func clearAll() async throws
    
    /// Get storage size in bytes
    func storageSize() async throws -> Int64
}

// MARK: - Persistence Errors

enum PersistenceError: LocalizedError, Equatable {
    case encodingFailed
    case decodingFailed
    case writeFailed(String)
    case readFailed(String)
    case deleteFailed(String)
    case notFound
    case invalidKey
    case storageFull
    case versionMismatch(stored: Int, current: Int)
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        case .writeFailed(let message):
            return "Failed to write: \(message)"
        case .readFailed(let message):
            return "Failed to read: \(message)"
        case .deleteFailed(let message):
            return "Failed to delete: \(message)"
        case .notFound:
            return "Item not found"
        case .invalidKey:
            return "Invalid storage key"
        case .storageFull:
            return "Storage is full"
        case .versionMismatch(let stored, let current):
            return "Version mismatch: stored=\(stored), current=\(current)"
        }
    }
}

// MARK: - Persistence Keys

/// Standard keys for cached data
enum PersistenceKeys {
    static let cachedItems = "cached_items"
    static let cachedUser = "cached_user"
    static let lastSync = "last_sync"
    static let cacheVersion = "cache_version"
}

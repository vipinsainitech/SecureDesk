//
//  KeychainService.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation
import Security

/// Protocol for keychain operations
protocol KeychainServiceProtocol: Sendable {
    
    /// Save data to keychain
    /// - Parameters:
    ///   - data: Data to store
    ///   - key: Key to identify the data
    /// - Throws: KeychainError on failure
    func save(_ data: Data, forKey key: String) throws
    
    /// Load data from keychain
    /// - Parameter key: Key to identify the data
    /// - Returns: Stored data or nil if not found
    /// - Throws: KeychainError on failure
    func load(forKey key: String) throws -> Data?
    
    /// Delete data from keychain
    /// - Parameter key: Key to identify the data
    /// - Throws: KeychainError on failure
    func delete(forKey key: String) throws
    
    /// Check if data exists for a key
    /// - Parameter key: Key to check
    /// - Returns: true if data exists
    func exists(forKey key: String) -> Bool
    
    /// Delete all items stored by this service
    /// - Throws: KeychainError on failure
    func deleteAll() throws
}

// MARK: - Keychain Service Implementation

/// Secure storage using macOS Keychain
final class KeychainService: KeychainServiceProtocol, @unchecked Sendable {
    
    // MARK: - Properties
    
    private let serviceName: String
    private let accessGroup: String?
    private let queue = DispatchQueue(label: "com.securedesk.keychain", qos: .userInitiated)
    
    // MARK: - Initialization
    
    init(serviceName: String = "com.kf.SecureDesk", accessGroup: String? = nil) {
        self.serviceName = serviceName
        self.accessGroup = accessGroup
    }
    
    // MARK: - Public Methods
    
    func save(_ data: Data, forKey key: String) throws {
        try queue.sync {
            // Delete existing item first
            try? deleteInternal(forKey: key)
            
            var query = baseQuery(forKey: key)
            query[kSecValueData as String] = data
            query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
            
            let status = SecItemAdd(query as CFDictionary, nil)
            
            guard status == errSecSuccess else {
                throw KeychainError.saveFailed(status)
            }
        }
    }
    
    func load(forKey key: String) throws -> Data? {
        try queue.sync {
            var query = baseQuery(forKey: key)
            query[kSecReturnData as String] = true
            query[kSecMatchLimit as String] = kSecMatchLimitOne
            
            var result: AnyObject?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            
            switch status {
            case errSecSuccess:
                return result as? Data
            case errSecItemNotFound:
                return nil
            default:
                throw KeychainError.loadFailed(status)
            }
        }
    }
    
    func delete(forKey key: String) throws {
        try queue.sync {
            try deleteInternal(forKey: key)
        }
    }
    
    func exists(forKey key: String) -> Bool {
        queue.sync {
            var query = baseQuery(forKey: key)
            query[kSecReturnData as String] = false
            
            let status = SecItemCopyMatching(query as CFDictionary, nil)
            return status == errSecSuccess
        }
    }
    
    func deleteAll() throws {
        try queue.sync {
            var query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName
            ]
            
            if let accessGroup = accessGroup {
                query[kSecAttrAccessGroup as String] = accessGroup
            }
            
            let status = SecItemDelete(query as CFDictionary)
            
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw KeychainError.deleteFailed(status)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func baseQuery(forKey key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        return query
    }
    
    private func deleteInternal(forKey key: String) throws {
        let query = baseQuery(forKey: key)
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

// MARK: - Keychain Errors

/// Errors that can occur during keychain operations
enum KeychainError: LocalizedError, Equatable {
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
    case encodingFailed
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let status):
            return "Failed to save to keychain: \(status)"
        case .loadFailed(let status):
            return "Failed to load from keychain: \(status)"
        case .deleteFailed(let status):
            return "Failed to delete from keychain: \(status)"
        case .encodingFailed:
            return "Failed to encode data for keychain"
        case .decodingFailed:
            return "Failed to decode data from keychain"
        }
    }
}

// MARK: - Keychain Keys

/// Keys used for storing specific data in keychain
enum KeychainKeys {
    static let accessToken = "accessToken"
    static let refreshToken = "refreshToken"
    static let authToken = "authToken"
    static let userId = "userId"
}

// MARK: - Codable Extension

extension KeychainServiceProtocol {
    
    /// Save a Codable object to keychain
    func save<T: Encodable>(_ object: T, forKey key: String) throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        do {
            let data = try encoder.encode(object)
            try save(data, forKey: key)
        } catch let error as KeychainError {
            throw error
        } catch {
            throw KeychainError.encodingFailed
        }
    }
    
    /// Load a Codable object from keychain
    func load<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = try load(forKey: key) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw KeychainError.decodingFailed
        }
    }
}

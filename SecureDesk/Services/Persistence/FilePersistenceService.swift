//
//  FilePersistenceService.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation

/// File-based persistence using JSON encoding
/// Stores data in the app's Application Support directory
actor FilePersistenceService: PersistenceServiceProtocol {
    
    // MARK: - Properties
    
    private let fileManager: FileManager
    private let baseDirectory: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    /// Current storage version for migration support
    static let currentVersion = 1
    
    // MARK: - Initialization
    
    init(
        fileManager: FileManager = .default,
        subdirectory: String = "Cache"
    ) throws {
        self.fileManager = fileManager
        
        // Get Application Support directory
        guard let appSupport = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first else {
            throw PersistenceError.writeFailed("Cannot access Application Support")
        }
        
        // Create app-specific subdirectory
        let bundleId = Bundle.main.bundleIdentifier ?? "SecureDesk"
        self.baseDirectory = appSupport
            .appendingPathComponent(bundleId)
            .appendingPathComponent(subdirectory)
        
        // Create directory if needed
        if !fileManager.fileExists(atPath: baseDirectory.path) {
            try fileManager.createDirectory(
                at: baseDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        // Configure encoder/decoder
        self.encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        self.decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - PersistenceServiceProtocol
    
    func save<T: Codable & Sendable>(_ object: T, forKey key: String) async throws {
        guard isValidKey(key) else {
            throw PersistenceError.invalidKey
        }
        
        let wrapper = VersionedWrapper(version: Self.currentVersion, data: object)
        
        do {
            let data = try encoder.encode(wrapper)
            let fileURL = url(forKey: key)
            try data.write(to: fileURL, options: .atomic)
            
            logOperation("Saved", key: key, size: data.count)
        } catch let error as EncodingError {
            throw PersistenceError.encodingFailed
        } catch {
            throw PersistenceError.writeFailed(error.localizedDescription)
        }
    }
    
    func load<T: Codable & Sendable>(_ type: T.Type, forKey key: String) async throws -> T? {
        guard isValidKey(key) else {
            throw PersistenceError.invalidKey
        }
        
        let fileURL = url(forKey: key)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let wrapper = try decoder.decode(VersionedWrapper<T>.self, from: data)
            
            // Check version compatibility
            guard wrapper.version <= Self.currentVersion else {
                throw PersistenceError.versionMismatch(
                    stored: wrapper.version,
                    current: Self.currentVersion
                )
            }
            
            logOperation("Loaded", key: key, size: data.count)
            return wrapper.data
        } catch let error as DecodingError {
            // Log decoding error details
            logError("Decoding failed for \(key): \(error)")
            throw PersistenceError.decodingFailed
        } catch let error as PersistenceError {
            throw error
        } catch {
            throw PersistenceError.readFailed(error.localizedDescription)
        }
    }
    
    func delete(forKey key: String) async throws {
        guard isValidKey(key) else {
            throw PersistenceError.invalidKey
        }
        
        let fileURL = url(forKey: key)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return // Already deleted, not an error
        }
        
        do {
            try fileManager.removeItem(at: fileURL)
            logOperation("Deleted", key: key, size: nil)
        } catch {
            throw PersistenceError.deleteFailed(error.localizedDescription)
        }
    }
    
    func exists(forKey key: String) async -> Bool {
        guard isValidKey(key) else { return false }
        return fileManager.fileExists(atPath: url(forKey: key).path)
    }
    
    func allKeys() async throws -> [String] {
        let contents = try fileManager.contentsOfDirectory(
            at: baseDirectory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )
        
        return contents
            .filter { $0.pathExtension == "json" }
            .map { $0.deletingPathExtension().lastPathComponent }
    }
    
    func clearAll() async throws {
        let contents = try fileManager.contentsOfDirectory(
            at: baseDirectory,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )
        
        for fileURL in contents {
            try fileManager.removeItem(at: fileURL)
        }
        
        logOperation("Cleared all", key: nil, size: nil)
    }
    
    func storageSize() async throws -> Int64 {
        let contents = try fileManager.contentsOfDirectory(
            at: baseDirectory,
            includingPropertiesForKeys: [.fileSizeKey],
            options: .skipsHiddenFiles
        )
        
        var totalSize: Int64 = 0
        
        for fileURL in contents {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            if let fileSize = attributes[.size] as? Int64 {
                totalSize += fileSize
            }
        }
        
        return totalSize
    }
    
    // MARK: - Private Methods
    
    private func url(forKey key: String) -> URL {
        baseDirectory.appendingPathComponent("\(key).json")
    }
    
    private func isValidKey(_ key: String) -> Bool {
        // Key must be non-empty and contain only safe characters
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_-"))
        return !key.isEmpty && key.unicodeScalars.allSatisfy { allowedCharacters.contains($0) }
    }
    
    private func logOperation(_ operation: String, key: String?, size: Int?) {
        #if DEBUG
        // Note: Simplified logging to avoid actor isolation issues
        var message = "[Persistence] \(operation)"
        if let key = key { message += " '\(key)'" }
        if let size = size { message += " (\(ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)))" }
        print(message)
        #endif
    }
    
    private func logError(_ message: String) {
        #if DEBUG
        print("[Persistence] ERROR: \(message)")
        #endif
    }
}

// MARK: - Versioned Wrapper

/// Wrapper for versioned storage
private struct VersionedWrapper<T: Codable>: Codable {
    let version: Int
    let timestamp: Date
    let data: T
    
    init(version: Int, data: T) {
        self.version = version
        self.timestamp = Date()
        self.data = data
    }
}

// MARK: - Storage Size Formatting

extension FilePersistenceService {
    
    /// Get human-readable storage size
    func formattedStorageSize() async throws -> String {
        let size = try await storageSize()
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

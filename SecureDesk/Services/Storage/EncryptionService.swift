//
//  EncryptionService.swift
//  SecureDesk
//
//  Created by Vipin Saini
//

import Foundation
import CryptoKit

/// Protocol for encryption operations
protocol EncryptionServiceProtocol: Sendable {
    
    /// Encrypt data using symmetric encryption
    /// - Parameters:
    ///   - data: Data to encrypt
    ///   - key: Encryption key
    /// - Returns: Encrypted data (nonce + ciphertext + tag)
    /// - Throws: EncryptionError on failure
    func encrypt(_ data: Data, using key: SymmetricKey) throws -> Data
    
    /// Decrypt data using symmetric encryption
    /// - Parameters:
    ///   - data: Encrypted data (nonce + ciphertext + tag)
    ///   - key: Encryption key
    /// - Returns: Decrypted data
    /// - Throws: EncryptionError on failure
    func decrypt(_ data: Data, using key: SymmetricKey) throws -> Data
    
    /// Generate a new symmetric key
    /// - Returns: New 256-bit symmetric key
    func generateKey() -> SymmetricKey
    
    /// Derive a key from a password
    /// - Parameters:
    ///   - password: Password string
    ///   - salt: Salt for key derivation
    /// - Returns: Derived symmetric key
    func deriveKey(from password: String, salt: Data) -> SymmetricKey
    
    /// Generate a secure random salt
    /// - Returns: Random salt data
    func generateSalt() -> Data
    
    /// Hash data using SHA256
    /// - Parameter data: Data to hash
    /// - Returns: SHA256 hash
    func hash(_ data: Data) -> Data
}

// MARK: - Encryption Service Implementation

/// Provides encryption operations using CryptoKit
final class EncryptionService: EncryptionServiceProtocol, Sendable {
    
    // MARK: - Constants
    
    private let saltLength = 32
    private let iterationCount = 100_000
    
    // MARK: - Initialization
    
    init() {}
    
    // MARK: - Public Methods
    
    func encrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            
            guard let combined = sealedBox.combined else {
                throw EncryptionError.encryptionFailed
            }
            
            return combined
        } catch let error as EncryptionError {
            throw error
        } catch {
            throw EncryptionError.encryptionFailed
        }
    }
    
    func decrypt(_ data: Data, using key: SymmetricKey) throws -> Data {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            let decrypted = try AES.GCM.open(sealedBox, using: key)
            return decrypted
        } catch {
            throw EncryptionError.decryptionFailed
        }
    }
    
    func generateKey() -> SymmetricKey {
        SymmetricKey(size: .bits256)
    }
    
    func deriveKey(from password: String, salt: Data) -> SymmetricKey {
        let passwordData = Data(password.utf8)
        
        // Use HKDF for key derivation
        let derivedKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: passwordData),
            salt: salt,
            info: Data("SecureDesk".utf8),
            outputByteCount: 32
        )
        
        return derivedKey
    }
    
    func generateSalt() -> Data {
        var salt = Data(count: saltLength)
        salt.withUnsafeMutableBytes { buffer in
            guard let pointer = buffer.baseAddress else { return }
            _ = SecRandomCopyBytes(kSecRandomDefault, saltLength, pointer)
        }
        return salt
    }
    
    func hash(_ data: Data) -> Data {
        let digest = SHA256.hash(data: data)
        return Data(digest)
    }
}

// MARK: - Encryption Errors

/// Errors that can occur during encryption operations
enum EncryptionError: LocalizedError, Equatable {
    case encryptionFailed
    case decryptionFailed
    case invalidKey
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .invalidKey:
            return "Invalid encryption key"
        case .invalidData:
            return "Invalid data format"
        }
    }
}

// MARK: - SymmetricKey Extension

extension SymmetricKey {
    
    /// Convert symmetric key to Data for storage
    var rawRepresentation: Data {
        withUnsafeBytes { Data($0) }
    }
    
    /// Create symmetric key from stored Data
    init(data: Data) {
        self.init(data: data)
    }
}

// MARK: - Data Extension for Hex

extension Data {
    
    /// Convert data to hex string
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
    
    /// Create data from hex string
    init?(hexString: String) {
        let length = hexString.count / 2
        var data = Data(capacity: length)
        
        var index = hexString.startIndex
        for _ in 0..<length {
            let nextIndex = hexString.index(index, offsetBy: 2)
            guard let byte = UInt8(hexString[index..<nextIndex], radix: 16) else {
                return nil
            }
            data.append(byte)
            index = nextIndex
        }
        
        self = data
    }
}

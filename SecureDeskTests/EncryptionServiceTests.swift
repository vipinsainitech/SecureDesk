//
//  EncryptionServiceTests.swift
//  SecureDeskTests
//
//  Created by Vipin Saini
//

import XCTest
import CryptoKit
@testable import SecureDesk

final class EncryptionServiceTests: XCTestCase {
    
    var sut: EncryptionService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = EncryptionService()
    }
    
    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Key Generation Tests
    
    func testGenerateKey_returns256BitKey() {
        // When
        let key = sut.generateKey()
        
        // Then
        XCTAssertEqual(key.bitCount, 256)
    }
    
    func testGenerateKey_producesUniqueKeys() {
        // When
        let key1 = sut.generateKey()
        let key2 = sut.generateKey()
        
        // Then
        XCTAssertNotEqual(key1.rawRepresentation, key2.rawRepresentation)
    }
    
    // MARK: - Salt Generation Tests
    
    func testGenerateSalt_returns32Bytes() {
        // When
        let salt = sut.generateSalt()
        
        // Then
        XCTAssertEqual(salt.count, 32)
    }
    
    func testGenerateSalt_producesUniqueSalts() {
        // When
        let salt1 = sut.generateSalt()
        let salt2 = sut.generateSalt()
        
        // Then
        XCTAssertNotEqual(salt1, salt2)
    }
    
    // MARK: - Encryption Tests
    
    func testEncryptDecrypt_roundTrip() throws {
        // Given
        let originalData = "Hello, SecureDesk!".data(using: .utf8)!
        let key = sut.generateKey()
        
        // When
        let encrypted = try sut.encrypt(originalData, using: key)
        let decrypted = try sut.decrypt(encrypted, using: key)
        
        // Then
        XCTAssertEqual(decrypted, originalData)
    }
    
    func testEncrypt_producesDifferentCiphertextEachTime() throws {
        // Given
        let data = "Test data".data(using: .utf8)!
        let key = sut.generateKey()
        
        // When
        let encrypted1 = try sut.encrypt(data, using: key)
        let encrypted2 = try sut.encrypt(data, using: key)
        
        // Then - Due to random nonce, ciphertext should differ
        XCTAssertNotEqual(encrypted1, encrypted2)
    }
    
    func testDecrypt_withWrongKey_throws() throws {
        // Given
        let data = "Secret data".data(using: .utf8)!
        let correctKey = sut.generateKey()
        let wrongKey = sut.generateKey()
        let encrypted = try sut.encrypt(data, using: correctKey)
        
        // When/Then
        XCTAssertThrowsError(try sut.decrypt(encrypted, using: wrongKey)) { error in
            XCTAssertEqual(error as? EncryptionError, .decryptionFailed)
        }
    }
    
    func testDecrypt_withCorruptedData_throws() throws {
        // Given
        let data = "Test data".data(using: .utf8)!
        let key = sut.generateKey()
        var encrypted = try sut.encrypt(data, using: key)
        
        // Corrupt the data
        if encrypted.count > 10 {
            encrypted[10] ^= 0xFF
        }
        
        // When/Then
        XCTAssertThrowsError(try sut.decrypt(encrypted, using: key))
    }
    
    // MARK: - Key Derivation Tests
    
    func testDeriveKey_producesConsistentKeys() {
        // Given
        let password = "mySecurePassword123"
        let salt = sut.generateSalt()
        
        // When
        let key1 = sut.deriveKey(from: password, salt: salt)
        let key2 = sut.deriveKey(from: password, salt: salt)
        
        // Then
        XCTAssertEqual(key1.rawRepresentation, key2.rawRepresentation)
    }
    
    func testDeriveKey_differentSaltsProduceDifferentKeys() {
        // Given
        let password = "mySecurePassword123"
        let salt1 = sut.generateSalt()
        let salt2 = sut.generateSalt()
        
        // When
        let key1 = sut.deriveKey(from: password, salt: salt1)
        let key2 = sut.deriveKey(from: password, salt: salt2)
        
        // Then
        XCTAssertNotEqual(key1.rawRepresentation, key2.rawRepresentation)
    }
    
    func testDeriveKey_differentPasswordsProduceDifferentKeys() {
        // Given
        let salt = sut.generateSalt()
        
        // When
        let key1 = sut.deriveKey(from: "password1", salt: salt)
        let key2 = sut.deriveKey(from: "password2", salt: salt)
        
        // Then
        XCTAssertNotEqual(key1.rawRepresentation, key2.rawRepresentation)
    }
    
    // MARK: - Hash Tests
    
    func testHash_producesConsistentHash() {
        // Given
        let data = "Hello, World!".data(using: .utf8)!
        
        // When
        let hash1 = sut.hash(data)
        let hash2 = sut.hash(data)
        
        // Then
        XCTAssertEqual(hash1, hash2)
    }
    
    func testHash_produces32Bytes() {
        // Given
        let data = "Test".data(using: .utf8)!
        
        // When
        let hash = sut.hash(data)
        
        // Then
        XCTAssertEqual(hash.count, 32) // SHA256 produces 32 bytes
    }
    
    func testHash_differentDataProducesDifferentHashes() {
        // Given
        let data1 = "Hello".data(using: .utf8)!
        let data2 = "World".data(using: .utf8)!
        
        // When
        let hash1 = sut.hash(data1)
        let hash2 = sut.hash(data2)
        
        // Then
        XCTAssertNotEqual(hash1, hash2)
    }
}

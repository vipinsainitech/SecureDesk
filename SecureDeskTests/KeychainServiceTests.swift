//
//  KeychainServiceTests.swift
//  SecureDeskTests
//
//  Created by Vipin Saini
//

import XCTest
@testable import SecureDesk

final class KeychainServiceTests: XCTestCase {
    
    var sut: KeychainService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        // Use a unique service name for tests to avoid conflicts
        sut = KeychainService(serviceName: "com.kf.SecureDesk.Tests")
        // Clean up any existing test data
        try? sut.deleteAll()
    }
    
    override func tearDownWithError() throws {
        // Clean up after tests
        try? sut.deleteAll()
        sut = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Save Tests
    
    func testSaveData_succeeds() throws {
        // Given
        let testData = "Hello, World!".data(using: .utf8)!
        let key = "testKey"
        
        // When/Then
        XCTAssertNoThrow(try sut.save(testData, forKey: key))
    }
    
    func testSaveData_overwritesExisting() throws {
        // Given
        let key = "testKey"
        let originalData = "Original".data(using: .utf8)!
        let newData = "New".data(using: .utf8)!
        
        // When
        try sut.save(originalData, forKey: key)
        try sut.save(newData, forKey: key)
        
        // Then
        let loaded = try sut.load(forKey: key)
        XCTAssertEqual(loaded, newData)
    }
    
    // MARK: - Load Tests
    
    func testLoadData_returnsNilForNonExistent() throws {
        // Given
        let key = "nonExistentKey"
        
        // When
        let loaded = try sut.load(forKey: key)
        
        // Then
        XCTAssertNil(loaded)
    }
    
    func testLoadData_returnsSavedData() throws {
        // Given
        let testData = "Test Data".data(using: .utf8)!
        let key = "testKey"
        try sut.save(testData, forKey: key)
        
        // When
        let loaded = try sut.load(forKey: key)
        
        // Then
        XCTAssertEqual(loaded, testData)
    }
    
    // MARK: - Delete Tests
    
    func testDeleteData_succeeds() throws {
        // Given
        let testData = "Test".data(using: .utf8)!
        let key = "testKey"
        try sut.save(testData, forKey: key)
        
        // When
        try sut.delete(forKey: key)
        
        // Then
        let loaded = try sut.load(forKey: key)
        XCTAssertNil(loaded)
    }
    
    func testDeleteData_succeedsForNonExistent() throws {
        // Given
        let key = "nonExistentKey"
        
        // When/Then
        XCTAssertNoThrow(try sut.delete(forKey: key))
    }
    
    // MARK: - Exists Tests
    
    func testExists_returnsFalseForNonExistent() {
        // Given
        let key = "nonExistentKey"
        
        // When
        let exists = sut.exists(forKey: key)
        
        // Then
        XCTAssertFalse(exists)
    }
    
    func testExists_returnsTrueForExisting() throws {
        // Given
        let testData = "Test".data(using: .utf8)!
        let key = "testKey"
        try sut.save(testData, forKey: key)
        
        // When
        let exists = sut.exists(forKey: key)
        
        // Then
        XCTAssertTrue(exists)
    }
    
    // MARK: - Codable Extension Tests
    
    func testSaveCodable_succeeds() throws {
        // Given
        let user = User.preview
        let key = "userKey"
        
        // When/Then
        XCTAssertNoThrow(try sut.save(user, forKey: key))
    }
    
    func testLoadCodable_returnsDecodedObject() throws {
        // Given
        let user = User.preview
        let key = "userKey"
        try sut.save(user, forKey: key)
        
        // When
        let loaded = try sut.load(User.self, forKey: key)
        
        // Then
        XCTAssertEqual(loaded?.id, user.id)
        XCTAssertEqual(loaded?.email, user.email)
        XCTAssertEqual(loaded?.name, user.name)
    }
    
    func testLoadCodable_returnsNilForNonExistent() throws {
        // Given
        let key = "nonExistentKey"
        
        // When
        let loaded = try sut.load(User.self, forKey: key)
        
        // Then
        XCTAssertNil(loaded)
    }
    
    // MARK: - Delete All Tests
    
    func testDeleteAll_removesAllItems() throws {
        // Given
        try sut.save("Data1".data(using: .utf8)!, forKey: "key1")
        try sut.save("Data2".data(using: .utf8)!, forKey: "key2")
        try sut.save("Data3".data(using: .utf8)!, forKey: "key3")
        
        // When
        try sut.deleteAll()
        
        // Then
        XCTAssertFalse(sut.exists(forKey: "key1"))
        XCTAssertFalse(sut.exists(forKey: "key2"))
        XCTAssertFalse(sut.exists(forKey: "key3"))
    }
}

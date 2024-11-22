//
//  DeviceUUIDTests.swift
//  MAGETests
//
//  Created by Dan Barela on 11/11/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import Security

@testable import MAGE

final class DeviceUUIDTests: XCTestCase {
    var previousUUID: UUID?
    
    override func setUp() {
        previousUUID = DeviceUUID.retrieveDeviceUUID()
        if let previousUUID {
            let query = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: DeviceUUIDKeys.service.rawValue,
                kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                kSecValueData: previousUUID.uuidString.data(using: .utf8)!
            ] as CFDictionary
            SecItemDelete(query)
        }
    }
    
    override func tearDown() {
        // put back the previous one
        if let previousUUID {
            
            if let currentUUID = DeviceUUID.retrieveDeviceUUID() {
                let query = [
                    kSecClass: kSecClassGenericPassword,
                    kSecAttrService: DeviceUUIDKeys.service.rawValue,
                    kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                    kSecValueData: currentUUID.uuidString.data(using: .utf8)!
                ] as CFDictionary
                SecItemDelete(query)
            }
            
            var uuidString = previousUUID.uuidString
            
            // Now store it in the KeyChain
            let query = [
                kSecClass: kSecClassGenericPassword,
                kSecAttrService: DeviceUUIDKeys.service.rawValue,
                kSecAttrAccessible: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                kSecValueData: uuidString.data(using: .utf8)!
            ] as CFDictionary
            
            let result = SecItemAdd(query, nil)
        }
    }

    func testPersist() {
        let persisted = DeviceUUID.persistUUIDToKeyChain()
        let retrieved = DeviceUUID.retrieveDeviceUUID()?.uuidString
        XCTAssertNotNil(persisted)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(persisted, retrieved)
    }
    
    func testRetrieveToCreateANewOne() {
        let persisted = DeviceUUID.retrieveDeviceUUID()?.uuidString
        let retrieved = DeviceUUID.retrieveDeviceUUID()?.uuidString
        XCTAssertNotNil(persisted)
        XCTAssertNotNil(retrieved)
        XCTAssertEqual(persisted, retrieved)
    }
}

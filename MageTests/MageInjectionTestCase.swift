//
//  MageInjectionTestCase.swift
//  MAGE
//
//  Created by Dan Barela on 9/25/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine
import OHHTTPStubs
import XCTest

@testable import MAGE

class MageInjectionTestCase: XCTestCase {
    var cancellables: Set<AnyCancellable> = Set()

    override func setUp() {
        TestHelpers.injectionSetup()
        TestHelpers.clearAndSetUpStack()
    }
    
    override func tearDown() {
        TestHelpers.clearAndSetUpStack()
        cancellables.removeAll()
        HTTPStubs.removeAllStubs();
    }
    
    func awaitPredicate(_ predicate: NSPredicate, timeout: TimeInterval = 2) async {
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: .none)
        await fulfillment(of: [expectation], timeout: timeout)
    }
    
    func awaitBlockTrue(block: @escaping () -> Bool, timeout: TimeInterval = 2) async {
        let predicate = NSPredicate(block: { _, _ in
            return block()
        })
        await awaitPredicate(predicate, timeout: timeout)
    }
}

class AsyncMageInjectionTestCase: XCTestCase {
    var cancellables: Set<AnyCancellable> = Set()

    override func setUp() async throws {
        TestHelpers.injectionSetup()
        TestHelpers.clearAndSetUpStack()
    }
    
    override func tearDown() async throws {
        TestHelpers.clearAndSetUpStack()
        cancellables.removeAll()
        HTTPStubs.removeAllStubs();
    }
    
    func awaitPredicate(_ predicate: NSPredicate, timeout: TimeInterval = 2) async {
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: .none)
        await fulfillment(of: [expectation], timeout: timeout)
    }
    
    func awaitBlockTrue(block: @escaping () -> Bool, timeout: TimeInterval = 2) async {
        let predicate = NSPredicate(block: { _, _ in
            return block()
        })
        await awaitPredicate(predicate, timeout: timeout)
    }
}

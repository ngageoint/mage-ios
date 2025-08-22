//
//  MageCoreDataTestCase.swift
//  MAGE
//
//  Created by Dan Barela on 9/25/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//
import Foundation
import Combine
import OHHTTPStubs
import CoreData
import KIF

@testable import MAGE

class MageCoreDataTestCase: MageInjectionTestCase {
    @Injected(\.persistence)
    var persistence: Persistence
    @Injected(\.nsManagedObjectContext)
    var context: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        persistence.clearAndSetupStack()
    }
    
    override func tearDown() {
        super.tearDown()
        persistence.clearAndSetupStack()
    }

    func awaitDidSave(block: @escaping () async -> Void) async {
        let didSave = expectation(forNotification: .NSManagedObjectContextDidSave, object: context) { notification in
            return notification.userInfo?["inserted"] != nil || notification.userInfo?["deleted"] != nil || notification.userInfo?["updated"] != nil
        }
        await block()
        await fulfillment(of: [didSave], timeout: 3)
    }
}

class AsyncMageCoreDataTestCase: AsyncMageInjectionTestCase {
    @Injected(\.persistence)
    var persistence: Persistence
    @Injected(\.nsManagedObjectContext)
    var context: NSManagedObjectContext!
    
    override func setUp() async throws {
        try await super.setUp()
        persistence.clearAndSetupStack()
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        persistence.clearAndSetupStack()
    }
    
    func awaitDidSave(block: @escaping () async -> Void) async {
        let didSave = expectation(forNotification: .NSManagedObjectContextDidSave, object: context) { notification in
            return notification.userInfo?["inserted"] != nil || notification.userInfo?["deleted"] != nil || notification.userInfo?["updated"] != nil
        }
        await block()
        await fulfillment(of: [didSave], timeout: 3)
    }
}

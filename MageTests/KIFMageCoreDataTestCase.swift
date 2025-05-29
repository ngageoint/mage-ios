//
//  KIFMageCoreDataTestCase.swift
//  MAGE
//
//  Created by Dan Barela on 9/25/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//
import Foundation

@testable import MAGE

class KIFMageCoreDataTestCase: KIFMageInjectionTestCase {
    @Injected(\.persistence)
    var persistence: Persistence
    @Injected(\.nsManagedObjectContext)
    var context: NSManagedObjectContext!
    
    override open func setUp() {
        super.setUp()
        persistence.clearAndSetupStack()
    }
    
    override open func tearDown() {
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

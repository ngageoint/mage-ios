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
}

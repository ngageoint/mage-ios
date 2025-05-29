//
//  AttachmentPushServiceTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 7/6/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import OHHTTPStubs

@testable import MAGE

class AttachmentPushServiceTests: AsyncMageCoreDataTestCase {
    
    @Injected(\.attachmentPushService)
    var attachmentPushService: AttachmentPushService
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        
        UserDefaults.standard.baseServerUrl = "https://magetest";
        Server.setCurrentEventId(1)
        MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "attachmentFormPlusOne")
        
        tester().waitForAnimationsToFinish()
        attachmentPushService.start(context)
        
        tester().waitForAnimationsToFinish()
        await awaitBlockTrue {
            @Injected(\.nsManagedObjectContext)
            var context: NSManagedObjectContext?
            return self.attachmentPushService.context == context
        }
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        attachmentPushService.stop()
    }
    
}

//
//  ObservationModelTests.swift
//  MAGETests
//
//  Created by Dan Barela on 8/29/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest

@testable import MAGE

final class ObservationModelTests: MageCoreDataTestCase {
    
    func testCreateWithErrorMessage() {
        guard let context = context else {
            XCTFail("No Managed Object Context")
            return
        }
        UserDefaults.standard.currentEventId = 1
        UserDefaults.standard.currentUserId = "user1"
        
        let properties: [AnyHashable: Any] = [
            ObservationKey.accuracy.key: 2.0,
            ObservationKey.provider.key: "gps",
            ObservationKey.forms.key: [
                [
                    FormKey.formId.key: 1,
                    FormKey.id.key: "form1",
                    "field0": "Field Value"
                ]
            ]
        ]
        
        context.performAndWait {
            let user = User(context: context)
            user.name = "Fred"
            user.remoteId = "user1"
            user.currentUser = true
            
            let observation = Observation(context: context)
            observation.remoteId = "1"
            observation.eventId = 1
            observation.user = user
            observation.geometry = SFPoint(x: 1.0, andY: 2.0)
            observation.timestamp = Date(timeIntervalSince1970: 20000)
            observation.lastModified = Date(timeIntervalSince1970: 10000)
            observation.properties = properties
            observation.error = [
                "errorMessage": "Error Message",
                "errorDescription": "Error Description",
                "errorStatusCode": 503
            ]
            
            let important = ObservationImportant(context: context)
            important.observation = observation
            important.important = true
            important.timestamp = Date(timeIntervalSince1970: 30000)
            important.userId = "user1"
            important.reason = "important"
            
            try? context.obtainPermanentIDs(for: [observation, user])
            try? context.save()
        }
        
        let observation = context.fetchFirst(Observation.self, key: "remoteId", value: "1")
        let user = context.fetchFirst(User.self, key: "remoteId", value: "user1")
        
        XCTAssertNotNil(observation)
        
        let model = ObservationModel(observation: observation!)
        
        XCTAssertEqual(model.observationId, observation?.objectID.uriRepresentation())
        XCTAssertEqual(model.remoteId, "1")
        XCTAssertEqual(model.geometry, observation?.geometry)
        XCTAssertEqual(model.eventId!, 1)
        XCTAssertEqual(model.accuracy, 2.0)
        XCTAssertEqual(model.provider, "gps")
        XCTAssertEqual(model.formId, 1)
        XCTAssertEqual(model.error, true)
        XCTAssertEqual(model.errorMessage, "Error Message")
        XCTAssertEqual(model.syncing, false)
        XCTAssertEqual(model.isDirty, true)
        XCTAssertEqual(model.lastModified, Date(timeIntervalSince1970: 10000))
        XCTAssertEqual(model.timestamp, Date(timeIntervalSince1970: 20000))
//        XCTAssertEqual(model.properties, properties)
        XCTAssertEqual(model.important?.important, true)
        XCTAssertEqual(model.important?.timestamp, Date(timeIntervalSince1970: 30000))
        XCTAssertEqual(model.important?.userId, "user1")
        XCTAssertEqual(model.important?.observationRemoteId, "1")
        XCTAssertEqual(model.important?.reason, "important")
        XCTAssertEqual(model.important?.eventId, 1)
        XCTAssertEqual(model.important?.userName, "Fred")
        XCTAssertEqual(model.userId, user?.objectID.uriRepresentation())
        XCTAssertEqual(model.coordinate?.latitude, 2.0)
        XCTAssertEqual(model.coordinate?.longitude, 1.0)
        XCTAssertEqual(model.accuracyDisplay, "GPS ± 2.00m")
        
        XCTAssertNotNil(model.observationForms)
        XCTAssertEqual(model.observationForms!.count, 1)
        let form = model.observationForms![0]
        XCTAssertEqual(form.eventFormId, 1)
        XCTAssertEqual(form.id, "form1")
        XCTAssertNotNil(model.primaryObservationForm)
    }

}

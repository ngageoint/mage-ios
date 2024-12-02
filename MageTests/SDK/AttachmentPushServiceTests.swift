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
        
        
        
        // TODO: try to remove this but it is really just for testing because in the real app
//         the context never changes
        tester().waitForAnimationsToFinish()
        await awaitBlockTrue {
            @Injected(\.nsManagedObjectContext)
            var context: NSManagedObjectContext?
            return self.attachmentPushService.context == context
        }
        
//        await observationPushService.start();
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        attachmentPushService.stop()
//        await observationPushService.stop();
    }
    
    @MainActor
    func testPushAttachment() async {
        let obs = MageCoreDataFixtures.addObservationToEvent()
        let attachment = MageCoreDataFixtures.addAttachment(observationUri: obs!.objectID.uriRepresentation(), localPath: OHPathForFile("icon27.png", AttachmentPushServiceTests.self)!)
        
        var uploadStubCalled = XCTestExpectation(description: "idStubCalled")

        stub(condition: isMethodPOST() &&
                isHost("magetest") &&
                isScheme("https") &&
                isPath("/api/events/1/observations/observationabc/attachments/attachmentabc")
        ) { (request) -> HTTPStubsResponse in
            let response: [String: Any] = [
                "id" : "observationabctest",
                "url": "https://magetest/api/events/1/observations/observationabc/attachments/attachmentabc"
            ];
            uploadStubCalled.fulfill()
            return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil);
        }
        
        print("XXX attachment is \(attachment)")
        
        print("XXX context in test is \(context)")
        context.performAndWait {
            let att = context.fetchFirst(Attachment.self, key: "remoteId", value: attachment!.remoteId!)
            att!.dirty = true
            print("xxx attachment now \(att)")
            do {
                try context.save()
            } catch {
                print("XXX error \(error)")
            }
        }
        
        await fulfillment(of: [uploadStubCalled], timeout: 2)
    }

//    func testShouldSaveAnObservationWithAnAttachment() async {
//        var idStubCalled = XCTestExpectation(description: "idStubCalled");
//        var createStubCalled = XCTestExpectation(description: "createStubCalled")
//
//        MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "attachmentForm")
//        
//        stub(condition: isMethodPOST() &&
//                isHost("magetest") &&
//                isScheme("https") &&
//                isPath("/api/events/1/observations/id")
//        ) { (request) -> HTTPStubsResponse in
//            let response: [String: Any] = [
//                "id" : "observationabctest",
//                "url": "https://magetest/api/events/1/observations/observationabctest"
//            ];
//            idStubCalled.fulfill()
//            return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil);
//        }
//        
//        let observationJsonRaw: [AnyHashable : Any] = [
//            "eventId":1,
//            "type":"Feature",
//            "geometry": [
//                "type":"Point",
//                "coordinates":[-104.899,39.627]
//            ],
//            "properties":[
//                "timestamp":"2021-07-06T18:26:51.468Z",
//                "forms":[
//                    "field23" : [
//                        [
//                            "action": "add",
//                            "observationFormId": 1,
//                            "name": "asam.png",
//                            "size": 41599,
//                            "type": "image/png"
//                        ]
//                    ]
//                ]
//            ],
//            "id":"observationabctest"
//        ]
//        
//        var expectedObservationJsonPut: [AnyHashable : Any] = observationJsonRaw;
//        expectedObservationJsonPut["url"] = "https://magetest/api/events/1/observations/observationabctest";
//        expectedObservationJsonPut["id"] = "observationabctest";
//        expectedObservationJsonPut["important"] = nil;
//        expectedObservationJsonPut["favoriteUserIds"] = nil;
//        expectedObservationJsonPut["attachments"] = nil;
//        expectedObservationJsonPut["lastModified"] = nil;
//        expectedObservationJsonPut["createdAt"] = nil;
//        expectedObservationJsonPut["eventId"] = nil;
//        expectedObservationJsonPut["timestamp"] = "2021-07-06T18:26:51.468Z";
//        expectedObservationJsonPut["state"] = [
//            "name": "active"
//        ]
//        
//        stub(condition:
//                isMethodPUT() &&
//                isHost("magetest") &&
//                isScheme("https") &&
//                isPath("/api/events/1/observations/observationabctest")
////                &&
////                hasJsonBody(expectedObservationJsonPut)
//        ) { (request) -> HTTPStubsResponse in
//            let httpBody = request.ohhttpStubs_httpBody!
//            let jsonBody = (try? JSONSerialization.jsonObject(with: httpBody, options: [])) as? [AnyHashable : Any]
//            print("XXX\n\(jsonBody)")
//            print("XXX expected \(expectedObservationJsonPut)")
//            let response: [String: Any] = [
//                "id" : "observationabctest",
//                "url": "https://magetest/api/events/1/observations/observationabctest"
//            ];
//            createStubCalled.fulfill()
//            return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil);
//        }
//        
//        var observationJsonToSaveInDb: [AnyHashable : Any] = observationJsonRaw
//        observationJsonToSaveInDb["url"] = nil;
//        observationJsonToSaveInDb["id"] = nil;
//        observationJsonToSaveInDb["important"] = nil;
//        observationJsonToSaveInDb["favoriteUserIds"] = nil;
//        observationJsonToSaveInDb["state"] = [
//            "name": "active"
//        ]
//        MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJsonToSaveInDb)
//        
//        guard let observation: Observation = Observation.mr_findFirst(in: context) else {
//            Nimble.fail()
//            return;
//        }
//        
//        expect(observation).toNot(beNil());
//
//        context.performAndWait {
//            let obs = context.fetchFirst(Observation.self, key: "eventId", value: 1)
//            obs!.dirty = true
//            try? context.save()
//        }
//        
//        await fulfillment(of: [idStubCalled], timeout: 2)
//        await fulfillment(of: [createStubCalled], timeout: 2)
//
//        expect(Observation.mr_findFirst()!.dirty).to(equal(false));
//    }
}

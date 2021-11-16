//
//  ObservationPushServiceTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 11/16/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Kingfisher
import OHHTTPStubs

@testable import MAGE

class ObservationPushServiceTests: KIFSpec {
    
    override func spec() {
        describe("Route Tests") {
            
            beforeEach {
                var cleared = false;
                while (!cleared) {
                    let clearMap = TestHelpers.clearAndSetUpStack()
                    cleared = (clearMap[String(describing: Observation.self)] ?? false) && (clearMap[String(describing: ObservationImportant.self)] ?? false) && (clearMap[String(describing: User.self)] ?? false)
                    
                    if (!cleared) {
                        cleared = Observation.mr_findAll(in: NSManagedObjectContext.mr_default())?.count == 0 && ObservationImportant.mr_findAll(in: NSManagedObjectContext.mr_default())?.count == 0 && User.mr_findAll(in: NSManagedObjectContext.mr_default())?.count == 0
                    }
                    
                    if (!cleared) {
                        Thread.sleep(forTimeInterval: 0.5);
                    }
                    
                }
                
                expect(Observation.mr_findAll(in: NSManagedObjectContext.mr_default())?.count).toEventually(equal(0), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Observations still exist in default");
                
                expect(Observation.mr_findAll(in: NSManagedObjectContext.mr_rootSaving())?.count).toEventually(equal(0), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Observations still exist in root");
                
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.serverMajorVersion = 6;
                UserDefaults.standard.serverMinorVersion = 0;
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "attachmentFormPlusOne")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                Server.setCurrentEventId(1);
                UserDefaults.standard.currentUserId = "userabc";
                NSManagedObject.mr_setDefaultBatchSize(0);
                ObservationPushService.singleton()?.start();
            }
            
            afterEach {
                ObservationPushService.singleton().stop();
                expect(ObservationPushService.singleton().isPushingFavorites()).toEventually(beFalse());
                expect(ObservationPushService.singleton().isPushingImportant()).toEventually(beFalse());
                expect(ObservationPushService.singleton().isPushingObservations()).toEventually(beFalse());
                NSManagedObject.mr_setDefaultBatchSize(20);
                TestHelpers.clearAndSetUpStack();
                HTTPStubs.removeAllStubs();
            }

            it("should tell the server to create an observation with an attachment") {
                
                var idStubCalled = false;
                
                stub(condition: isMethodPOST() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/observations/id")
                ) { (request) -> HTTPStubsResponse in
                    let response: [String: Any] = [
                        "id" : "observationabctest",
                        "url": "https://magetest/api/events/1/observations/observationabctest"
                    ];
                    idStubCalled = true;
                    return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil);
                }
                
                var createStubCalled = false;
                
                let url = Bundle(for: ObservationTests.self).url(forResource: "test_marker", withExtension: "png")!
                
                var baseObservationJson: [AnyHashable : Any] = [:]
                baseObservationJson["important"] = nil;
                baseObservationJson["favoriteUserIds"] = nil;
                baseObservationJson["attachments"] = nil;
                baseObservationJson["lastModified"] = nil;
                baseObservationJson["createdAt"] = nil;
                baseObservationJson["eventId"] = 1;
                baseObservationJson["timestamp"] = "2020-06-05T17:21:46.969Z";
                baseObservationJson["state"] = [
                    "name": "active"
                ]
                baseObservationJson["geometry"] = [
                    "coordinates": [-1.1, 2.1],
                    "type": "Point"
                ]
                baseObservationJson["properties"] = [
                    "timestamp": "2020-06-05T17:21:46.969Z",
                    "forms": [[
                        "formId":162,
                        "field0":"Turkey"
                    ],
                      [
                        "formId": 163,
                        "field0": [[
                            "action": "add",
                            "name": "test_marker.png",
                            "contentType": "image/png",
                            "localPath": url.path,
                            "fieldName": "field0"
                        ]]
                    ]]
                ];
                
                stub(condition: isMethodPUT() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/observations/observationabctest")
                ) { (request) -> HTTPStubsResponse in
                    createStubCalled = true;
                    let stubPath = OHPathForFile("attachmentPushTestResponse.json", ObservationPushServiceTests.self);
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
                }
                
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: baseObservationJson)
                
                MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                    guard let observation: Observation = Observation.mr_findFirst(in: localContext) else {
                        Nimble.fail()
                        return;
                    }
                    observation.dirty = true;
                });
                
                expect(idStubCalled).toEventually(beTrue());
                expect(createStubCalled).toEventually(beTrue());
                
                expect(Attachment.mr_findAll()?.count).toEventually(equal(1))
            }
        }
    }
}

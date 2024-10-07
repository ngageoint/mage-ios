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

class AttachmentPushServiceTests: QuickSpec {
    
    override func spec() {
        
        xdescribe("AttachmentPushServiceTests") {
            
            @Injected(\.persistence)
            var coreDataStack: Persistence
            @Injected(\.nsManagedObjectContext)
            var context: NSManagedObjectContext!
            
            beforeEach {
                coreDataStack.clearAndSetupStack()
                context = coreDataStack.getContext()
                InjectedValues[\.nsManagedObjectContext] = context
                NSManagedObject.mr_setDefaultBatchSize(0);
                
                TestHelpers.clearAndSetUpStack()
                
                UserDefaults.standard.baseServerUrl = "https://magetest";
                ObservationPushService.singleton.start();
            }
            
            afterEach {
                InjectedValues[\.nsManagedObjectContext] = nil
                coreDataStack.clearAndSetupStack()
                ObservationPushService.singleton.stop();
                HTTPStubs.removeAllStubs();
            }

            it("should save an observation with an attachment") {
                var idStubCalled = false;
                var createStubCalled = false;

                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "attachmentForm")
                
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
                
                let observationJsonRaw: [AnyHashable : Any] = [
                    "eventId":1,
                    "type":"Feature",
                    "geometry": [
                        "type":"Point",
                        "coordinates":[-104.899,39.627]
                    ],
                    "properties":[
                        "timestamp":"2021-07-06T18:26:51.468Z",
                        "forms":[
                            "field23" : [
                                [
                                    "id": 0,
                                    "observationFormId": 1,
                                    "name": "asam.png",
                                    "size": 41599,
                                    "type": "image/png"
                                ]
                            ]
                        ]
                    ],
                    "id":"observationabctest"
                ]
                
                var expectedObservationJsonPut: [AnyHashable : Any] = observationJsonRaw;
                expectedObservationJsonPut["url"] = "https://magetest/api/events/1/observations/observationabctest";
                expectedObservationJsonPut["id"] = "observationabctest";
                expectedObservationJsonPut["important"] = nil;
                expectedObservationJsonPut["favoriteUserIds"] = nil;
                expectedObservationJsonPut["attachments"] = nil;
                expectedObservationJsonPut["lastModified"] = nil;
                expectedObservationJsonPut["createdAt"] = nil;
                expectedObservationJsonPut["eventId"] = nil;
                expectedObservationJsonPut["timestamp"] = "2020-06-05T17:21:46.969Z";
                expectedObservationJsonPut["state"] = [
                    "name": "active"
                ]
                
                stub(condition: isMethodPUT() &&
                        isHost("magetest") &&
                        isScheme("https") &&
                        isPath("/api/events/1/observations/observationabctest")
                        &&
                        hasJsonBody(expectedObservationJsonPut)
                ) { (request) -> HTTPStubsResponse in
                    let response: [String: Any] = [
                        "id" : "observationabctest",
                        "url": "https://magetest/api/events/1/observations/observationabctest"
                    ];
                    createStubCalled = true;
                    return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil);
                }
                
                var observationJsonToSaveInDb: [AnyHashable : Any] = observationJsonRaw
                observationJsonToSaveInDb["url"] = nil;
                observationJsonToSaveInDb["id"] = nil;
                observationJsonToSaveInDb["important"] = nil;
                observationJsonToSaveInDb["favoriteUserIds"] = nil;
                observationJsonToSaveInDb["state"] = [
                    "name": "active"
                ]
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJsonToSaveInDb)
                
                guard let observation: Observation = Observation.mr_findFirst() else {
                    Nimble.fail()
                    return;
                }
                
                expect(observation).toNot(beNil());

                context.performAndWait {
                    let obs = context.fetchFirst(Observation.self, key: "eventId", value: 1)
                    obs!.dirty = true
                    try? context.save()
                }
                
                expect(idStubCalled).toEventually(beTrue());
                expect(createStubCalled).toEventually(beTrue());
                
                expect(Observation.mr_findFirst()!.dirty).toEventually(equal(false));
            }
        }
    }
}

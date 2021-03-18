//
//  ObservationTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 3/17/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Kingfisher
import OHHTTPStubs

@testable import MAGE

class ObservationTests: QuickSpec {
    
    override func spec() {
        
        describe("Tests") {
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();
                UserDefaults.standard.baseServerUrl = "https://magetest";

                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                Server.setCurrentEventId(1);
                UserDefaults.standard.currentUserId = "userabc";
                NSManagedObject.mr_setDefaultBatchSize(0);
                ObservationPushService.singleton()?.start();
            }
            
            afterEach {
                ObservationPushService.singleton().stop();
                NSManagedObject.mr_setDefaultBatchSize(20);
                TestHelpers.cleanUpStack();
                HTTPStubs.removeAllStubs();
            }
            
            it("should tell the server to delete an observation") {
                
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                guard let observation: Observation = Observation.mr_findFirst() else {
                    Nimble.fail()
                    return;
                }
                
                var stubCalled = false;
                
                stub(condition: isMethodPOST() &&
                        isHost("magetest") &&
                        isScheme("https") &&
                        isPath("/api/events/1/observations/observationabc/states") &&
                        hasJsonBody(["name": "archive"])
                ) { (request) -> HTTPStubsResponse in
                    let response: [String: Any] = [ : ];
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil);
                }
                
                expect(observation).toNot(beNil());
                MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                    guard let localObservation = observation.mr_(in: localContext) else {
                        Nimble.fail()
                        return;
                    }
                    // archive the observation
                    localObservation.state = 0;
                    localObservation.dirty = true;
                })
                
                expect(stubCalled).toEventually(beTrue());
                
                expect(Observation.mr_findFirst()).toEventually(beNil());
            }
            
            it("should tell the server to delete an observation and remove it if a 404 is returned") {
                
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                guard let observation: Observation = Observation.mr_findFirst() else {
                    Nimble.fail()
                    return;
                }
                
                var stubCalled = false;
                
                stub(condition: isMethodPOST() &&
                        isHost("magetest") &&
                        isScheme("https") &&
                        isPath("/api/events/1/observations/observationabc/states") &&
                        hasJsonBody(["name": "archive"])
                ) { (request) -> HTTPStubsResponse in
                    let response: [String: Any] = [ : ];
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: response, statusCode: 404, headers: nil);
                }
                
                expect(observation).toNot(beNil());
                MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                    guard let localObservation = observation.mr_(in: localContext) else {
                        Nimble.fail()
                        return;
                    }
                    // archive the observation
                    localObservation.state = 0;
                    localObservation.dirty = true;
                })
                
                expect(stubCalled).toEventually(beTrue());
                
                expect(Observation.mr_findFirst()).toEventually(beNil());
            }
            
            it("should tell the server to create an observation") {
                var idStubCalled = false;
                var createStubCalled = false;
                
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
                
                var expectedObservationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                expectedObservationJson["url"] = "https://magetest/api/events/1/observations/observationabctest";
                expectedObservationJson["id"] = "observationabctest";
                expectedObservationJson["important"] = nil;
                expectedObservationJson["favoriteUserIds"] = nil;
                expectedObservationJson["attachments"] = nil;
                expectedObservationJson["lastModified"] = nil;
                expectedObservationJson["createdAt"] = nil;
                expectedObservationJson["eventId"] = nil;
                expectedObservationJson["timestamp"] = "2020-06-05T17:21:46.969Z";
                expectedObservationJson["state"] = [
                    "name": "active"
                ]
                
                stub(condition: isMethodPUT() &&
                        isHost("magetest") &&
                        isScheme("https") &&
                        isPath("/api/events/1/observations/observationabctest")
                        &&
                        hasJsonBody(expectedObservationJson)
                ) { (request) -> HTTPStubsResponse in
                    let response: [String: Any] = [
                        "id" : "observationabctest",
                        "url": "https://magetest/api/events/1/observations/observationabctest"
                    ];
                    createStubCalled = true;
                    return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil);
                }
                
                var observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                observationJson["url"] = nil;
                observationJson["id"] = nil;
                observationJson["important"] = nil;
                observationJson["favoriteUserIds"] = nil;
                observationJson["state"] = [
                    "name": "active"
                ]
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                guard let observation: Observation = Observation.mr_findFirst() else {
                    Nimble.fail()
                    return;
                }
                
                expect(observation).toNot(beNil());
                MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                    guard let localObservation = observation.mr_(in: localContext) else {
                        Nimble.fail()
                        return;
                    }
                    localObservation.dirty = true;
                })
                
                expect(idStubCalled).toEventually(beTrue());
                expect(createStubCalled).toEventually(beTrue());
                
                expect(Observation.mr_findFirst()!.dirty).toEventually(equal(0));
            }
            
            it("should tell the server to update an observation") {
                var updateStubCalled = false;
                
                var expectedObservationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                expectedObservationJson["url"] = "https://magetest/api/events/1/observations/observationabctest";
                expectedObservationJson["id"] = "observationabctest";
                expectedObservationJson["important"] = nil;
                expectedObservationJson["favoriteUserIds"] = nil;
                expectedObservationJson["attachments"] = nil;
                expectedObservationJson["lastModified"] = nil;
                expectedObservationJson["createdAt"] = nil;
                expectedObservationJson["eventId"] = nil;
                expectedObservationJson["timestamp"] = "2020-06-05T17:21:46.969Z";
                expectedObservationJson["state"] = [
                    "name": "active"
                ]
                
                stub(condition: isMethodPUT() &&
                        isHost("magetest") &&
                        isScheme("https") &&
                        isPath("/api/events/1/observations/observationabctest")
                        &&
                        hasJsonBody(expectedObservationJson)
                ) { (request) -> HTTPStubsResponse in
                    let response: [String: Any] = [
                        "id" : "observationabctest",
                        "url": "https://magetest/api/events/1/observations/observationabctest"
                    ];
                    updateStubCalled = true;
                    return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil);
                }
                
                var observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                observationJson["url"] = "https://magetest/api/events/1/observations/observationabctest";
                observationJson["id"] = "observationabctest";
                observationJson["important"] = nil;
                observationJson["favoriteUserIds"] = nil;
                observationJson["state"] = [
                    "name": "active"
                ]
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                guard let observation: Observation = Observation.mr_findFirst() else {
                    Nimble.fail()
                    return;
                }
                
                expect(observation).toNot(beNil());
                MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                    guard let localObservation = observation.mr_(in: localContext) else {
                        Nimble.fail()
                        return;
                    }
                    localObservation.dirty = true;
                })
                
                expect(updateStubCalled).toEventually(beTrue());
                
                expect(Observation.mr_findFirst()!.dirty).toEventually(equal(0));
            }
            
            it("should tell the server to add an observation favorite") {
                var stubCalled = false;
                
                stub(condition: isMethodPUT() &&
                        isHost("magetest") &&
                        isScheme("https") &&
                        isPath("/api/events/1/observations/observationabctest/favorite")
                ) { (request) -> HTTPStubsResponse in
                    let response: [String: Any] = [:];
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil);
                }
                
                var observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                observationJson["url"] = "https://magetest/api/events/1/observations/observationabctest";
                observationJson["id"] = "observationabctest";
                observationJson["important"] = nil;
                observationJson["favoriteUserIds"] = nil;
                observationJson["state"] = [
                    "name": "active"
                ]
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                guard let observation: Observation = Observation.mr_findFirst() else {
                    Nimble.fail()
                    return;
                }
                
                expect(observation).toNot(beNil());
                expect(Observation.mr_findFirst()!.favorites?.count).toEventually(equal(0));
                
                MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                    guard let localObservation = observation.mr_(in: localContext) else {
                        Nimble.fail()
                        return;
                    }
                    localObservation.toggleFavorite(completion: nil);
                })
                
                expect(stubCalled).toEventually(beTrue());
                print("favorites \(Observation.mr_findFirst()!.favorites)")
                expect(Observation.mr_findFirst()!.favorites!.count).toEventually(equal(1));
                expect(Observation.mr_findFirst()!.favorites!.first!.dirty).toEventually(beFalse());
            }
            
            it("should tell the server to delete an observation favorite") {
                var stubCalled = false;
                
                stub(condition: isMethodDELETE() &&
                        isHost("magetest") &&
                        isScheme("https") &&
                        isPath("/api/events/1/observations/observationabctest/favorite")
                ) { (request) -> HTTPStubsResponse in
                    let response: [String: Any] = [:];
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil);
                }
                
                var observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                observationJson["url"] = "https://magetest/api/events/1/observations/observationabctest";
                observationJson["id"] = "observationabctest";
                observationJson["important"] = nil;
                observationJson["state"] = [
                    "name": "active"
                ]
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                guard let observation: Observation = Observation.mr_findFirst() else {
                    Nimble.fail()
                    return;
                }
                
                expect(observation).toNot(beNil());
                expect(Observation.mr_findFirst()!.favorites?.count).toEventually(equal(1));
                
                MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                    guard let localObservation = observation.mr_(in: localContext) else {
                        Nimble.fail()
                        return;
                    }
                    localObservation.toggleFavorite(completion: nil);
                })
                
                expect(stubCalled).toEventually(beTrue());
                
                expect(Observation.mr_findFirst()!.favorites!.first!.favorite).toEventually(beFalse());
                expect(Observation.mr_findFirst()!.favorites!.first!.dirty).toEventually(beFalse());
            }
        }
    }
}

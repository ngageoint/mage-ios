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
        xdescribe("Route Tests") {
            var coreDataStack: TestCoreDataStack?
            var context: NSManagedObjectContext!
            
            beforeEach {
                coreDataStack = TestCoreDataStack()
                context = coreDataStack!.persistentContainer.newBackgroundContext()
                InjectedValues[\.nsManagedObjectContext] = context
                
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
                
                MageCoreDataFixtures.addEvent(context: context, remoteId: 1, name: "Event", formsJsonFile: "attachmentFormPlusOne")
                MageCoreDataFixtures.addUser(userId: "userabc", context: context)
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc", context: context)
                Server.setCurrentEventId(1);
                UserDefaults.standard.currentUserId = "userabc";
                NSManagedObject.mr_setDefaultBatchSize(0);
                UserDefaults.standard.loginParameters = [
                    LoginParametersKey.acceptedConsent.key: LoginParametersKey.agree.key,
                    LoginParametersKey.tokenExpirationDate.key: Date().addingTimeInterval(1000000)
                ]
                ObservationPushService.singleton.start();
            }
            
            afterEach {
                InjectedValues[\.nsManagedObjectContext] = nil
                coreDataStack!.reset()
                ObservationPushService.singleton.stop();
//                expect(ObservationPushService.singleton.isPushingFavorites()).toEventually(beFalse());
//                expect(ObservationPushService.singleton.isPushingImportant()).toEventually(beFalse());
                expect(ObservationPushService.singleton.isPushingObservations()).toEventually(beFalse());
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
                
                let url = Bundle(for: ObservationPushServiceTests.self).url(forResource: "test_marker", withExtension: "png")!
                
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
                expect(ObservationPushService.singleton.isPushingObservations()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
            }
            
            it("should create an observation and call delegates") {
                let delegate1 = MockObservationPushDelegate();
                let delegate2 = MockObservationPushDelegate();
                ObservationPushService.singleton.addDelegate(delegate: delegate1);
                ObservationPushService.singleton.addDelegate(delegate: delegate2);
                
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
                
                MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                    guard let observation: Observation = Observation.mr_findFirst(in: localContext) else {
                        Nimble.fail()
                        return;
                    }
                    observation.dirty = true;
                });
                
                expect(idStubCalled).toEventually(beTrue());
                expect(createStubCalled).toEventually(beTrue());
                expect(delegate1.didPushCalled).toEventually(beTrue());
                expect(delegate1.pushedObservation).toNot(beNil());
                expect(delegate1.error).to(beNil());
                expect(delegate2.didPushCalled).toEventually(beTrue());
                expect(delegate2.pushedObservation).toNot(beNil());
                expect(delegate2.error).to(beNil());
                expect(ObservationPushService.singleton.isPushingObservations()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
            }
            
            it("should not create an observation if the user preferences say to not") {
                // 2 is none
                UserDefaults.standard.set(2, forKey: "observationPushNetworkOption")
                
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
                
                var observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                observationJson["url"] = nil;
                observationJson["id"] = nil;
                observationJson["important"] = nil;
                observationJson["favoriteUserIds"] = nil;
                observationJson["state"] = [
                    "name": "active"
                ]
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                    guard let observation: Observation = Observation.mr_findFirst(in: localContext) else {
                        Nimble.fail()
                        return;
                    }
                    observation.dirty = true;
                });
                
                expect(ObservationPushService.singleton.isPushingObservations()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
                expect(Observation.mr_findFirst()?.dirty).toEventually(beTrue());
            }
            
            it("should create an observation and call delegates upon server failure") {
                let delegate1 = MockObservationPushDelegate();
                let delegate2 = MockObservationPushDelegate();
                ObservationPushService.singleton.addDelegate(delegate: delegate1);
                ObservationPushService.singleton.addDelegate(delegate: delegate2);
                
                var idStubCalled = false;
                
                stub(condition: isMethodPOST() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/observations/id")
                ) { (request) -> HTTPStubsResponse in
                    idStubCalled = true;
                    let notConnectedError = NSError(domain: NSURLErrorDomain, code: URLError.notConnectedToInternet.rawValue)
                    return HTTPStubsResponse(error: notConnectedError);
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
                
                var observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                observationJson["url"] = nil;
                observationJson["id"] = nil;
                observationJson["important"] = nil;
                observationJson["favoriteUserIds"] = nil;
                observationJson["state"] = [
                    "name": "active"
                ]
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                    guard let observation: Observation = Observation.mr_findFirst(in: localContext) else {
                        Nimble.fail()
                        return;
                    }
                    observation.dirty = true;
                });
                
                expect(idStubCalled).toEventually(beTrue());
                expect(delegate1.didPushCalled).toEventually(beTrue());
                expect(delegate1.pushedObservation).toNot(beNil());
                expect(delegate1.error).toNot(beNil());
                expect(delegate2.didPushCalled).toEventually(beTrue());
                expect(delegate2.pushedObservation).toNot(beNil());
                expect(delegate2.error).toNot(beNil());
                
                expect(delegate1.pushedObservation?.errorMessage).to(equal("The operation couldn’t be completed. (NSURLErrorDomain error -1009.)"))
                expect(ObservationPushService.singleton.isPushingObservations()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
            }
            
            it("should create an observation and call delegates upon validation error") {
                let delegate1 = MockObservationPushDelegate();
                let delegate2 = MockObservationPushDelegate();
                ObservationPushService.singleton.addDelegate(delegate: delegate1);
                ObservationPushService.singleton.addDelegate(delegate: delegate2);
                
                var idStubCalled = false;
                
                stub(condition: isMethodPOST() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/observations/id")
                ) { (request) -> HTTPStubsResponse in
                    idStubCalled = true;
                    return HTTPStubsResponse(data: String("Validation error").data(using: .utf8)!, statusCode: 400, headers: nil);
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
                
                var observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                observationJson["url"] = nil;
                observationJson["id"] = nil;
                observationJson["important"] = nil;
                observationJson["favoriteUserIds"] = nil;
                observationJson["state"] = [
                    "name": "active"
                ]
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
                    guard let observation: Observation = Observation.mr_findFirst(in: localContext) else {
                        Nimble.fail()
                        return;
                    }
                    observation.dirty = true;
                });
                
                expect(idStubCalled).toEventually(beTrue());
                expect(delegate1.didPushCalled).toEventually(beTrue());
                expect(delegate1.pushedObservation).toNot(beNil());
                expect(delegate1.error).toNot(beNil());
                expect(delegate2.didPushCalled).toEventually(beTrue());
                expect(delegate2.pushedObservation).toNot(beNil());
                expect(delegate2.error).toNot(beNil());
                
                expect(delegate1.pushedObservation?.errorMessage).to(equal("Validation error"))
                
                expect(ObservationPushService.singleton.isPushingObservations()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
            }
            
            it("should tell the server to add an observation favorite") {
                var stubCalled = false;
                
                stub(condition: isMethodPUT() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/observations/observationabctest/favorite")
                ) { (request) -> HTTPStubsResponse in
                    print("stub called")
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
                guard let observation: Observation = MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson) else {
                    Nimble.fail()
                    return;
                }
//                var toggleFavoriteCalled = false;
//                observation.toggleFavorite(completion: { success, error in
//                    expect(success).to(beTrue());
//                    print("success")
//                    toggleFavoriteCalled = true;
//                })
                
                expect(stubCalled).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "stub not called");
//                expect(toggleFavoriteCalled).toEventually(beTrue());
                expect(ObservationFavorite.mr_findFirst()?.dirty).toEventually(beFalse());
//                expect(ObservationPushService.singleton.isPushingFavorites()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
            }
            
            it("should tell the server to add an observation favorite and then remove it before it is sent") {
                // 2 is none
                UserDefaults.standard.set(2, forKey: "observationPushNetworkOption")
                
                var observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                observationJson["url"] = "https://magetest/api/events/1/observations/observationabctest";
                observationJson["id"] = "observationabctest";
                observationJson["important"] = nil;
                observationJson["favoriteUserIds"] = nil;
                observationJson["state"] = [
                    "name": "active"
                ]
                guard let observation: Observation = MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson) else {
                    Nimble.fail()
                    return;
                }
//                var toggleFavoriteCalled = false;
//                observation.toggleFavorite(completion: { success, error in
//                    expect(success).to(beTrue());
//                    print("success")
//                    toggleFavoriteCalled = true;
//                })
//                
//                expect(toggleFavoriteCalled).toEventually(beTrue());
                expect(ObservationFavorite.mr_findFirst()?.dirty).toEventually(beTrue());
                expect(ObservationFavorite.mr_findFirst()?.favorite).toEventually(beTrue());
//                expect(ObservationPushService.singleton.isPushingFavorites()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
                
                expect(Observation.mr_findFirst()?.favoritesMap).toEventuallyNot(beEmpty());
                var toggleFavoriteAgainCalled = false;
//                Observation.mr_findFirst()?.toggleFavorite(completion: { success, error in
//                    toggleFavoriteAgainCalled = true;
//                })
                
                expect(toggleFavoriteAgainCalled).toEventually(beTrue());
                expect(ObservationFavorite.mr_findFirst()?.dirty).toEventually(beTrue());
                expect(ObservationFavorite.mr_findFirst()?.favorite).toEventually(beFalse());
//                expect(ObservationPushService.singleton.isPushingFavorites()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
            }
            
            it("should not push a favorite if the user preferences say to not") {
                // 2 is none
                UserDefaults.standard.set(2, forKey: "observationPushNetworkOption")
                
                var observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                observationJson["url"] = "https://magetest/api/events/1/observations/observationabctest";
                observationJson["id"] = "observationabctest";
                observationJson["important"] = nil;
                observationJson["favoriteUserIds"] = nil;
                observationJson["state"] = [
                    "name": "active"
                ]
                guard let observation: Observation = MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson) else {
                    Nimble.fail()
                    return;
                }
//                var toggleFavoriteCalled = false;
//                observation.toggleFavorite(completion: { success, error in
//                    expect(success).to(beTrue());
//                    print("success")
//                    toggleFavoriteCalled = true;
//                })
//                expect(toggleFavoriteCalled).toEventually(beTrue());
                expect(ObservationFavorite.mr_findFirst()?.dirty).toEventually(beTrue());
//                expect(ObservationPushService.singleton.isPushingFavorites()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
            }
            
            it("should fail to add an observation favorite") {
                var stubCalled = false;
                
                stub(condition: isMethodPUT() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/observations/observationabctest/favorite")
                ) { (request) -> HTTPStubsResponse in
                    print("stub called")
                    let response: [String: Any] = [:];
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: response, statusCode: 400, headers: nil);
                }
                
                var observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                observationJson["url"] = "https://magetest/api/events/1/observations/observationabctest";
                observationJson["id"] = "observationabctest";
                observationJson["important"] = nil;
                observationJson["favoriteUserIds"] = nil;
                observationJson["state"] = [
                    "name": "active"
                ]
                guard let observation: Observation = MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson) else {
                    Nimble.fail()
                    return;
                }
//                var toggleFavoriteCalled = false;
//                // this is only saving to the database, not the server
//                observation.toggleFavorite(completion: { success, error in
//                    expect(success).to(beTrue());
//                    toggleFavoriteCalled = true;
//                })
                
                expect(stubCalled).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "stub not called");
//                expect(toggleFavoriteCalled).toEventually(beTrue());
                expect(ObservationFavorite.mr_findFirst()?.dirty).toEventually(beTrue());
//                expect(ObservationPushService.singleton.isPushingFavorites()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
            }
            
            it("should tell the server to make the observation important") {
                var stubCalled = false;
                
                stub(condition: isMethodPUT() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/observations/observationabctest/important")
                ) { (request) -> HTTPStubsResponse in
                    let response: [String: Any] = [
                        "important": true
                    ];
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
                guard let observation: Observation = MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson) else {
                    Nimble.fail()
                    return;
                }
                
                let localObservation = observation.mr_(in: NSManagedObjectContext.mr_default())!;
                
                expect(localObservation).toNot(beNil());
                expect(localObservation.isImportant).to(beFalse());
//                localObservation.flagImportant(description: "new important", completion: nil)
                
                expect(stubCalled).toEventually(beTrue());
                expect(Observation.mr_findFirst()!.isImportant).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find observation");
//                expect(ObservationPushService.singleton.isPushingImportant()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
                expect(ObservationImportant.mr_findFirst()?.dirty).toEventually(beFalse());
                expect(ObservationImportant.mr_findFirst()?.important).toEventually(beTrue());
            }
            
            it("should not tell the server to make the observation important if the user preferences say to not") {
                // 2 is none
                UserDefaults.standard.set(2, forKey: "observationPushNetworkOption")

                var observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                observationJson["url"] = "https://magetest/api/events/1/observations/observationabctest";
                observationJson["id"] = "observationabctest";
                observationJson["important"] = nil;
                observationJson["favoriteUserIds"] = nil;
                observationJson["state"] = [
                    "name": "active"
                ]
                guard let observation: Observation = MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson) else {
                    Nimble.fail()
                    return;
                }
                
                let localObservation = observation.mr_(in: NSManagedObjectContext.mr_default())!;
                
                expect(localObservation).toNot(beNil());
                expect(localObservation.isImportant).to(beFalse());
//                localObservation.flagImportant(description: "new important", completion: nil)
                
                expect(Observation.mr_findFirst()!.isImportant).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find observation");
//                expect(ObservationPushService.singleton.isPushingImportant()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
                expect(ObservationImportant.mr_findFirst()?.dirty).toEventually(beTrue());
                expect(ObservationImportant.mr_findFirst()?.important).toEventually(beTrue());
            }
            
            it("should fail to make the observation important") {
                var stubCalled = false;
                
                stub(condition: isMethodPUT() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/observations/observationabctest/important")
                ) { (request) -> HTTPStubsResponse in
                    let response: [String: Any] = [:];
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: response, statusCode: 400, headers: nil);
                }
                
                var observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                observationJson["url"] = "https://magetest/api/events/1/observations/observationabctest";
                observationJson["id"] = "observationabctest";
                observationJson["important"] = nil;
                observationJson["favoriteUserIds"] = nil;
                observationJson["state"] = [
                    "name": "active"
                ]
                guard let observation: Observation = MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson) else {
                    Nimble.fail()
                    return;
                }
                
                let localObservation = observation.mr_(in: NSManagedObjectContext.mr_default())!;
                
                expect(localObservation).toNot(beNil());
                expect(localObservation.isImportant).to(beFalse());
//                localObservation.flagImportant(description: "new important", completion: nil)
                
                expect(stubCalled).toEventually(beTrue());
                expect(Observation.mr_findFirst()!.isImportant).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find observation");
//                expect(ObservationPushService.singleton.isPushingImportant()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
                expect(ObservationImportant.mr_findFirst()?.dirty).toEventually(beTrue());
                expect(ObservationImportant.mr_findFirst()?.important).toEventually(beTrue());
            }
            
            it("should push the important again because the server still thinks it is unimportant") {
                var stubCalled = false;
                
                stub(condition: isMethodPUT() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/events/1/observations/observationabctest/important")
                ) { (request) -> HTTPStubsResponse in
                    let response: [String: Any] = [:];
                    print("SSSSSSSSS STUB CALLED")
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
                guard let observation: Observation = MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson) else {
                    Nimble.fail()
                    return;
                }
                
                let localObservation = observation.mr_(in: NSManagedObjectContext.mr_default())!;
                
                expect(localObservation).toNot(beNil());
                expect(localObservation.isImportant).to(beFalse());
//                localObservation.flagImportant(description: "new important", completion: nil)
                
                expect(stubCalled).toEventually(beTrue());
                expect(Observation.mr_findFirst()!.isImportant).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find observation");
//                expect(ObservationPushService.singleton.isPushingImportant()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
                expect(ObservationImportant.mr_findFirst()?.dirty).toEventually(beTrue());
                expect(ObservationImportant.mr_findFirst()?.important).toEventually(beTrue());
            }
        }
    }
}

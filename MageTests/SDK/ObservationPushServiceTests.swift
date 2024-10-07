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

class ObservationPushServiceTests: MageCoreDataTestCase {
    
    override func setUp() {
        super.setUp()
        UserDefaults.standard.baseServerUrl = "https://magetest";
        UserDefaults.standard.serverMajorVersion = 6;
        UserDefaults.standard.serverMinorVersion = 0;
        
        MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "attachmentFormPlusOne")
        MageCoreDataFixtures.addUser(userId: "userabc")
        MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
        Server.setCurrentEventId(1);
        UserDefaults.standard.currentUserId = "userabc";
        
        UserDefaults.standard.loginParameters = [
            LoginParametersKey.acceptedConsent.key: LoginParametersKey.agree.key,
            LoginParametersKey.tokenExpirationDate.key: Date().addingTimeInterval(1000000)
        ]
        ObservationPushService.singleton.start();
    }
    
    override func tearDown() {
        super.tearDown()
        ObservationPushService.singleton.stop();
    }
    
    func testShouldTellTheServerToCreateAnObservationWithAnAttachment() {
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
        
        context.performAndWait {
            let obs = context.fetchFirst(Observation.self, key: "eventId", value: 1)
            obs!.dirty = true
            try? context.save()
        }
        
        
        //                MagicalRecord.save(blockAndWait: { (localContext: NSManagedObjectContext) in
        guard let observation: Observation = Observation.mr_findFirst(in: context) else {
            Nimble.fail()
            return;
        }
        print("obs \(observation)")
        //                    observation.dirty = true;
        //                });
        
        expect(idStubCalled).toEventually(beTrue());
        expect(createStubCalled).toEventually(beTrue());
        
        expect(Attachment.mr_findAll()?.count).toEventually(equal(1))
        expect(ObservationPushService.singleton.isPushingObservations()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
    }
    
    func testShouldCreateAnObservationAndCallDelegates() {
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
    
    func testShouldNotCreateAnObservationIfTheUserPreferencesSayToNot() {
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
    
    func testShouldCreateAnObservationAndCallDelegatesUponServerFailure() {
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
    
    func testShouldCreateAnObservationAndCallDelegatesUponValidationError() {
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
    
    func testShouldTellTheServerToAddAnObservationFavorite() {
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
        
        @Injected(\.observationFavoriteRepository)
        var repository: ObservationFavoriteRepository
        repository.toggleFavorite(observationUri: observation.objectID.uriRepresentation(), userRemoteId: "userabc")
        //                var toggleFavoriteCalled = false;
        //                observation.toggleFavorite(completion: { success, error in
        //                    expect(success).to(beTrue());
        //                    print("success")
        //                    toggleFavoriteCalled = true;
        //                })
        //                expect(ObservationFavorite.mr_findFirst()?.dirty).toEventually(beFalse());
        expect(stubCalled).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "stub not called");
        //                expect(toggleFavoriteCalled).toEventually(beTrue());
        
        //                expect(ObservationPushService.singleton.isPushingFavorites()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
    }
    
    func testShouldTellTheServerToAddAnObservationFavoriteAndThenRemoteItBeforeItIsSent() {
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
        @Injected(\.observationFavoriteRepository)
        var repository: ObservationFavoriteRepository
        repository.toggleFavorite(observationUri: observation.objectID.uriRepresentation(), userRemoteId: "userabc")
        //
        //                expect(toggleFavoriteCalled).toEventually(beTrue());
        expect(ObservationFavorite.mr_findFirst()?.dirty).toEventually(beTrue());
        expect(ObservationFavorite.mr_findFirst()?.favorite).toEventually(beTrue());
        //                expect(ObservationPushService.singleton.isPushingFavorites()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
        
        expect(Observation.mr_findFirst()?.favoritesMap).toEventuallyNot(beEmpty());
        //                var toggleFavoriteAgainCalled = false;
        
        repository.toggleFavorite(observationUri: observation.objectID.uriRepresentation(), userRemoteId: "userabc")
        //                Observation.mr_findFirst()?.toggleFavorite(completion: { success, error in
        //                    toggleFavoriteAgainCalled = true;
        //                })
        
        //                expect(toggleFavoriteAgainCalled).toEventually(beTrue());
        expect(ObservationFavorite.mr_findFirst()?.dirty).toEventually(beTrue());
        expect(ObservationFavorite.mr_findFirst()?.favorite).toEventually(beFalse());
        //                expect(ObservationPushService.singleton.isPushingFavorites()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
    }
    
    func testShouldNotPushAFavoriteIfTheUserPreferencesSayToNot() {
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
        @Injected(\.observationFavoriteRepository)
        var repository: ObservationFavoriteRepository
        repository.toggleFavorite(observationUri: observation.objectID.uriRepresentation(), userRemoteId: "userabc")
        //                expect(toggleFavoriteCalled).toEventually(beTrue());
        expect(ObservationFavorite.mr_findFirst()?.dirty).toEventually(beTrue());
        //                expect(ObservationPushService.singleton.isPushingFavorites()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
    }
    
    func testShouldFailToAddAnObservationFavorite() {
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
        @Injected(\.observationFavoriteRepository)
        var repository: ObservationFavoriteRepository
        repository.toggleFavorite(observationUri: observation.objectID.uriRepresentation(), userRemoteId: "userabc")
        
        expect(stubCalled).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "stub not called");
        //                expect(toggleFavoriteCalled).toEventually(beTrue());
        expect(ObservationFavorite.mr_findFirst()?.dirty).toEventually(beTrue());
        //                expect(ObservationPushService.singleton.isPushingFavorites()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
    }
    
    func testShouldTellTheServerToMakeTheObservationImportant() {
        print("XXX Starting the test")
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
        
        @Injected(\.observationImportantRepository)
        var repository: ObservationImportantRepository
        repository.flagImportant(observationUri: localObservation.objectID.uriRepresentation(), reason: "new important")
        
        expect(Observation.mr_findFirst()!.isImportant).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find observation");
        
        expect(stubCalled).toEventually(beTrue());
        
        //                expect(ObservationPushService.singleton.isPushingImportant()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
        //                expect(ObservationImportant.mr_findFirst()?.dirty).toEventually(beFalse());
        expect(ObservationImportant.mr_findFirst()?.important).toEventually(beTrue());
    }
    
    func testShouldNotTellTheServerTOMakeTheObservationImportantIfTheUserPreferencesSayToNot() {
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
        @Injected(\.observationImportantRepository)
        var repository: ObservationImportantRepository
        repository.flagImportant(observationUri: observation.objectID.uriRepresentation(), reason: "new important")
        
        expect(Observation.mr_findFirst()!.isImportant).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find observation");
        //                expect(ObservationPushService.singleton.isPushingImportant()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
        expect(ObservationImportant.mr_findFirst()?.dirty).toEventually(beTrue());
        expect(ObservationImportant.mr_findFirst()?.important).toEventually(beTrue());
    }
    
    func testShouldFailToMakeTheObservationImportant() {
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
        @Injected(\.observationImportantRepository)
        var repository: ObservationImportantRepository
        repository.flagImportant(observationUri: observation.objectID.uriRepresentation(), reason: "new important")
        
        expect(stubCalled).toEventually(beTrue());
        expect(Observation.mr_findFirst()!.isImportant).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find observation");
//                expect(ObservationPushService.singleton.isPushingImportant()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
        expect(ObservationImportant.mr_findFirst()?.dirty).toEventually(beTrue());
        expect(ObservationImportant.mr_findFirst()?.important).toEventually(beTrue());
    }
            
    func testShouldPushTheImportantAgainBecauseTheServerStillThinksItIsUnimportant() {
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
        @Injected(\.observationImportantRepository)
        var repository: ObservationImportantRepository
        repository.flagImportant(observationUri: observation.objectID.uriRepresentation(), reason: "new important")
        
        expect(stubCalled).toEventually(beTrue());
        expect(Observation.mr_findFirst()!.isImportant).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find observation");
//                expect(ObservationPushService.singleton.isPushingImportant()).toEventually(beFalse(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Observation Push Service is still pushing");
        expect(ObservationImportant.mr_findFirst()?.dirty).toEventually(beTrue());
        expect(ObservationImportant.mr_findFirst()?.important).toEventually(beTrue());
    }
}

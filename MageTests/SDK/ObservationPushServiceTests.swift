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

// TODO: Tests are flaky
class ObservationPushServiceTests: AsyncMageCoreDataTestCase {
    
    @Injected(\.observationPushService)
    var pushService: ObservationPushService
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
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
        
        await pushService.start();
    }
    
    @MainActor
    override func tearDown() async throws {
        try await super.tearDown()
        await pushService.stop();
    }
    
    func testShouldTellTheServerToCreateAnObservationWithAnAttachment() async {
        let idStubCalled = XCTestExpectation(description: "idStubCalled");
        
        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/observations/id")
        ) { (request) -> HTTPStubsResponse in
            let response: [String: Any] = [
                "id" : "observationabctest",
                "url": "https://magetest/api/events/1/observations/observationabctest"
            ];
            idStubCalled.fulfill()
            return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil);
        }
        
        let createStubCalled = XCTestExpectation(description: "createStubCalled");
        
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
            createStubCalled.fulfill()
            let stubPath = OHPathForFile("attachmentPushTestResponse.json", ObservationPushServiceTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: baseObservationJson)
        
        context.performAndWait {
            let obs = context.fetchFirst(Observation.self, key: "eventId", value: 1)
            obs!.dirty = true
            try? context.save()
        }
        
        guard let observation: Observation = Observation.mr_findFirst(in: context) else {
            Nimble.fail()
            return;
        }

        await fulfillment(of: [idStubCalled, createStubCalled], timeout: 2)
        await awaitBlockTrue {
            Attachment.mr_findAll()?.count == 1
        }
        var isPushing = await pushService.isPushingObservations()
        expect(isPushing).to(beFalse());
    }
    
    func testShouldTellTheServerToCreateAnObservationWithAnAttachmentAndThenHaveItDeletedFromTheServer() async {
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
        var observationPushedAgain = false
        
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
            if (!createStubCalled) {
                createStubCalled = true;
                let stubPath = OHPathForFile("attachmentPushTestResponse.json", ObservationPushServiceTests.self);
                return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
            } else {
                // for the second call, return a no attachment observation
                observationPushedAgain = true;
                let stubPath = OHPathForFile("observationNoAttachmentResponse.json", ObservationPushServiceTests.self);
                return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
            }
        }
        
        await awaitDidSave {
            MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: baseObservationJson)
        
            self.context.performAndWait {
                let obs = self.context.fetchFirst(Observation.self, key: "eventId", value: 1)
                obs!.dirty = true
                try? self.context.save()
            }
        }
        
        guard let observation: Observation = Observation.mr_findFirst(in: context) else {
            Nimble.fail()
            return;
        }
        
        await awaitBlockTrue {
            return idStubCalled == true
        }
        await awaitBlockTrue { return createStubCalled == true }
        await awaitBlockTrue { return Attachment.mr_findAll()?.count == 1 }
        
        // Now return the observation json with no attachments so they are deleted locally
        await awaitDidSave {
            self.context.performAndWait {
                let obs = self.context.fetchFirst(Observation.self, key: "eventId", value: 1)
                obs!.dirty = true
                try? self.context.save()
            }
        }
        
        await awaitBlockTrue { observationPushedAgain == true }
        await awaitBlockTrue { Attachment.mr_findAll()?.count == 0 }
    }
    
    func testShouldCreateAnObservationAndCallDelegates() async {
        let delegate1 = MockObservationPushDelegate();
        let delegate2 = MockObservationPushDelegate();
        await pushService.addDelegate(delegate: delegate1);
        await pushService.addDelegate(delegate: delegate2);
        
        let idStubCalled = XCTestExpectation(description: "idstubcalled")
        let createStubCalled = XCTestExpectation(description: "createstubcalled")
        
        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/observations/id")
        ) { (request) -> HTTPStubsResponse in
            let response: [String: Any] = [
                "id" : "observationabctest",
                "url": "https://magetest/api/events/1/observations/observationabctest"
            ];
            idStubCalled.fulfill()
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
            createStubCalled.fulfill()
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
        
        await fulfillment(of: [idStubCalled, createStubCalled], timeout: 2)
        await awaitBlockTrue {
            return delegate1.didPushCalled
            && delegate1.pushedObservation != nil
            && delegate1.error == nil
            && delegate2.didPushCalled
            && delegate2.pushedObservation != nil
            && delegate2.error == nil
        }
    }
    
    func testShouldNotCreateAnObservationIfTheUserPreferencesSayToNot() {
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
        
        expect(Observation.mr_findFirst()?.dirty).toEventually(beTrue());
    }
    
    @MainActor
    func testShouldCreateAnObservationAndCallDelegatesUponServerFailure() async {
        let delegate1 = MockObservationPushDelegate();
        let delegate2 = MockObservationPushDelegate();
        await pushService.addDelegate(delegate: delegate1);
        await pushService.addDelegate(delegate: delegate2);
        
        let idStubCalled = XCTestExpectation(description: "idStubCalled");
        
        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/observations/id")
        ) { (request) -> HTTPStubsResponse in
            idStubCalled.fulfill()
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
        
        context.performAndWait {
            if let observation = try? context.fetchFirst(Observation.self) {
                observation.dirty = true
            } else {
                XCTFail("Could not find observation")
            }
            try? context.save()
        }

        await fulfillment(of: [idStubCalled], timeout: 2)
        tester().waitForAnimationsToFinish()
        await awaitBlockTrue {
            return delegate1.didPushCalled
            && delegate1.pushedObservation != nil
            && delegate1.error != nil
            && delegate2.didPushCalled
            && delegate2.pushedObservation != nil
            && delegate2.error != nil
        }
        expect(delegate1.pushedObservation?.errorMessage).to(equal("The operation couldn’t be completed. (NSURLErrorDomain error -1009.)"))
    }
    
    func testShouldCreateAnObservationAndCallDelegatesUponValidationError() async {
        let delegate1 = MockObservationPushDelegate();
        let delegate2 = MockObservationPushDelegate();
        await pushService.addDelegate(delegate: delegate1);
        await pushService.addDelegate(delegate: delegate2);
        
        let idStubCalled = XCTestExpectation(description: "idstubcalled");
        
        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/observations/id")
        ) { (request) -> HTTPStubsResponse in
            idStubCalled.fulfill()
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
        
        await fulfillment(of: [idStubCalled], timeout: 2)
        await awaitBlockTrue {
            return delegate1.didPushCalled
            && delegate1.pushedObservation != nil
            && delegate1.error != nil
            && delegate2.didPushCalled
            && delegate2.pushedObservation != nil
            && delegate2.error != nil
        }
        
        expect(delegate1.pushedObservation?.errorMessage).to(equal("Validation error"))
    }
    
    func testShouldTellTheServerToAddAnObservationFavorite() {
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
        guard let observation: Observation = MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson) else {
            Nimble.fail()
            return;
        }
        
        @Injected(\.observationFavoriteRepository)
        var repository: ObservationFavoriteRepository
        repository.toggleFavorite(observationUri: observation.objectID.uriRepresentation(), userRemoteId: "userabc")

        expect(stubCalled).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(5), pollInterval: DispatchTimeInterval.seconds(1), description: "stub not called");
    }
    
    func testShouldTellTheServerToAddAnObservationFavoriteAndThenRemoteItBeforeItIsSent() {
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
        @Injected(\.observationFavoriteRepository)
        var repository: ObservationFavoriteRepository
        repository.toggleFavorite(observationUri: observation.objectID.uriRepresentation(), userRemoteId: "userabc")
        expect(ObservationFavorite.mr_findFirst()?.dirty).toEventually(beTrue());
        expect(ObservationFavorite.mr_findFirst()?.favorite).toEventually(beTrue());
        
        expect(Observation.mr_findFirst()?.favoritesMap).toEventuallyNot(beEmpty());
        
        repository.toggleFavorite(observationUri: observation.objectID.uriRepresentation(), userRemoteId: "userabc")
        expect(ObservationFavorite.mr_findFirst()?.dirty).toEventually(beTrue());
        expect(ObservationFavorite.mr_findFirst()?.favorite).toEventually(beFalse());
    }
    
    func testShouldNotPushAFavoriteIfTheUserPreferencesSayToNot() {
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
        @Injected(\.observationFavoriteRepository)
        var repository: ObservationFavoriteRepository
        repository.toggleFavorite(observationUri: observation.objectID.uriRepresentation(), userRemoteId: "userabc")
        expect(ObservationFavorite.mr_findFirst()?.dirty).toEventually(beTrue());
    }
    
    func testShouldFailToAddAnObservationFavorite() async {
        var stubCalled = false;
        
        stub(condition: isMethodPUT() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/events/1/observations/observationabctest/favorite")
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

        await awaitDidSave {
            @Injected(\.observationFavoriteRepository)
            var repository: ObservationFavoriteRepository
            repository.toggleFavorite(observationUri: observation.objectID.uriRepresentation(), userRemoteId: "userabc")
        }
        
        let predicate = NSPredicate { _, _ in
            return stubCalled == true
        }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: .none)
        await fulfillment(of: [expectation], timeout: 2)
        
        let predicate2 = NSPredicate { _, _ in
            let first = ObservationFavorite.mr_findFirst()
            return first?.dirty == false && first?.favorite == true
        }
        let expectation2 = XCTNSPredicateExpectation(predicate: predicate2, object: .none)
        await fulfillment(of: [expectation2], timeout: 2)
    }
    
    func testShouldTellTheServerToMakeTheObservationImportant() {
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
        
        @Injected(\.observationImportantRepository)
        var repository: ObservationImportantRepository
        repository.flagImportant(observationUri: localObservation.objectID.uriRepresentation(), reason: "new important")
        
        expect(Observation.mr_findFirst()!.isImportant).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find observation");
        
        expect(stubCalled).toEventually(beTrue());
        
        expect(ObservationImportant.mr_findFirst()?.important).toEventually(beTrue());
    }
    
    func testShouldNotTellTheServerTOMakeTheObservationImportantIfTheUserPreferencesSayToNot() {
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
        @Injected(\.observationImportantRepository)
        var repository: ObservationImportantRepository
        repository.flagImportant(observationUri: observation.objectID.uriRepresentation(), reason: "new important")
        
        expect(Observation.mr_findFirst()!.isImportant).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find observation");
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
        @Injected(\.observationImportantRepository)
        var repository: ObservationImportantRepository
        repository.flagImportant(observationUri: observation.objectID.uriRepresentation(), reason: "new important")
        
        expect(stubCalled).toEventually(beTrue());
        expect(Observation.mr_findFirst()!.isImportant).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find observation");
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
        @Injected(\.observationImportantRepository)
        var repository: ObservationImportantRepository
        repository.flagImportant(observationUri: observation.objectID.uriRepresentation(), reason: "new important")
        
        expect(stubCalled).toEventually(beTrue());
        expect(Observation.mr_findFirst()!.isImportant).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(2), pollInterval: DispatchTimeInterval.milliseconds(200), description: "Did not find observation");
        expect(ObservationImportant.mr_findFirst()?.dirty).toEventually(beTrue());
        expect(ObservationImportant.mr_findFirst()?.important).toEventually(beTrue());
    }
}

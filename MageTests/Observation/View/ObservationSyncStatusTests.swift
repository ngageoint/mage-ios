//
//  ObservationSyncStatusTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 12/22/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Nimble_Snapshots
import OHHTTPStubs

@testable import MAGE

class ObservationSyncStatusTests: KIFSpec {
    
    override func spec() {
        
        describe("ObservationSyncStatusTests") {
            let recordSnapshots = false;
            
            var view: UIView!
            var controller: UIViewController!
            var window: UIWindow!;
            
            func maybeRecordSnapshot(_ view: UIView, recordThisSnapshot: Bool = false) {
                print("Record snapshot?", recordSnapshots);
                if (recordSnapshots || recordThisSnapshot) {
                    expect(view) == recordSnapshot(usesDrawRect: true);
                } else {
                    expect(view).to(haveValidSnapshot(usesDrawRect: true));
                }
            }
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();

                controller = UIViewController();
                window = TestHelpers.getKeyWindowVisible();
                window.rootViewController = controller;
                view = UIView(forAutoLayout: ());
                view.backgroundColor = .systemBackground;
                controller.view.addSubview(view);
                view.autoPinEdgesToSuperviewEdges();
            }
            
            afterEach {
                TestHelpers.cleanUpStack();
                controller.dismiss(animated: false, completion: nil);
                window.rootViewController = nil;
                controller = nil;
                view = nil;
                HTTPStubs.removeAllStubs();
            }
            
            it("not current user") {
                UserDefaults.standard.currentUserId = "different";
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                var observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                
                let syncStatus = ObservationSyncStatus(observation: observation);
                syncStatus.applyTheme(withScheme: MAGEScheme.scheme());
                view.addSubview(syncStatus);
                syncStatus.autoPinEdge(toSuperviewEdge: .left);
                syncStatus.autoPinEdge(toSuperviewEdge: .right);
                syncStatus.autoAlignAxis(toSuperviewAxis: .horizontal);
                expect(syncStatus.isHidden).to(beFalse());
            }
        
            it("pushed as current user") {
                UserDefaults.standard.currentUserId = "userabc";
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                var observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                
                let syncStatus = ObservationSyncStatus(observation: observation);
                syncStatus.applyTheme(withScheme: MAGEScheme.scheme());
                view.addSubview(syncStatus);
                syncStatus.autoPinEdge(toSuperviewEdge: .left);
                syncStatus.autoPinEdge(toSuperviewEdge: .right);
                syncStatus.autoAlignAxis(toSuperviewAxis: .horizontal);
                
                tester().waitForView(withAccessibilityLabel: "Pushed on June 5, 2020 at 11:21:54 AM MDT");
                
                maybeRecordSnapshot(syncStatus);
            }
            
            it("dirty") {
                UserDefaults.standard.currentUserId = "userabc";
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                var observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                observation.dirty = true;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                
                let syncStatus = ObservationSyncStatus(observation: observation);
                syncStatus.applyTheme(withScheme: MAGEScheme.scheme());
                view.addSubview(syncStatus);
                syncStatus.autoPinEdge(toSuperviewEdge: .left);
                syncStatus.autoPinEdge(toSuperviewEdge: .right);
                syncStatus.autoAlignAxis(toSuperviewAxis: .horizontal);
                TestHelpers.printAllAccessibilityLabelsInWindows();
                tester().waitForView(withAccessibilityLabel: "Changes Queued");
                tester().waitForView(withAccessibilityLabel: "Sync Now");
                
                maybeRecordSnapshot(syncStatus);
            }
            
            it("error") {
                UserDefaults.standard.currentUserId = "userabc";
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                observation.dirty = true;
                observation.error = [
                    kObservationErrorStatusCode: 503,
                    kObservationErrorMessage: "Something Bad"
                ]
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                
                let syncStatus = ObservationSyncStatus(observation: observation);
                syncStatus.applyTheme(withScheme: MAGEScheme.scheme());
                view.addSubview(syncStatus);
                syncStatus.autoPinEdge(toSuperviewEdge: .left);
                syncStatus.autoPinEdge(toSuperviewEdge: .right);
                syncStatus.autoAlignAxis(toSuperviewAxis: .horizontal);
                
                tester().waitForView(withAccessibilityLabel: "Error Pushing Changes\nSomething Bad");
                
                maybeRecordSnapshot(syncStatus);
            }
            
            it("tap sync now") {
                UserDefaults.standard.currentUserId = "userabc";
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                var stubCalled = false;
                
                // make the request take long enough to capture the image
                stub(condition: isMethodPUT() && isHost("magetest") && isScheme("https") && isPath("/api/events/1/observations/observationabc")) { (request) -> HTTPStubsResponse in
                    let response: [String: Any] = [ : ];
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil);
                }
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                observation.dirty = true;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                
                let syncStatus = ObservationSyncStatus(observation: observation);
                syncStatus.applyTheme(withScheme: MAGEScheme.scheme());
                view.addSubview(syncStatus);
                syncStatus.autoPinEdge(toSuperviewEdge: .left);
                syncStatus.autoPinEdge(toSuperviewEdge: .right);
                syncStatus.autoAlignAxis(toSuperviewAxis: .horizontal);
                
                tester().waitForView(withAccessibilityLabel: "Sync Now");
                tester().tapView(withAccessibilityLabel: "Sync Now");
                expect(stubCalled).toEventually(beTrue());
                maybeRecordSnapshot(syncStatus);
            }
            
            it("dirty and then pushed") {
                UserDefaults.standard.currentUserId = "userabc";
                
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                observation.dirty = true;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                
                let syncStatus = ObservationSyncStatus(observation: observation);
                syncStatus.applyTheme(withScheme: MAGEScheme.scheme());
                view.addSubview(syncStatus);
                syncStatus.autoPinEdge(toSuperviewEdge: .left);
                syncStatus.autoPinEdge(toSuperviewEdge: .right);
                syncStatus.autoAlignAxis(toSuperviewAxis: .horizontal);
                tester().wait(forTimeInterval: 0.5);
                observation.dirty = false;
                syncStatus.updateObservationStatus();
                maybeRecordSnapshot(syncStatus);
            }
        }
    }
}

//
//  ObservationViewCardCollectionViewControllerTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 12/16/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Nimble_Snapshots
import OHHTTPStubs
import MagicalRecord

@testable import MAGE

class ObservationViewCardCollectionViewControllerTests: KIFSpec {
    
    override func spec() {
        
        describe("ObservationViewCardCollectionViewControllerTests") {
            let recordSnapshots = false;
            Nimble_Snapshots.setNimbleTolerance(0.1);
            
            var controller: UINavigationController!
            var view: UIView!
            var window: UIWindow!;
            
            func createGradientImage(startColor: UIColor, endColor: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
                let rect = CGRect(origin: .zero, size: size)
                let gradientLayer = CAGradientLayer()
                gradientLayer.frame = rect
                gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
                
                UIGraphicsBeginImageContext(gradientLayer.bounds.size)
                gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
                let image = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                guard let cgImage = image?.cgImage else { return UIImage() }
                return UIImage(cgImage: cgImage)
            }
            
            func maybeRecordSnapshot(_ view: UIView, recordThisSnapshot: Bool = false, usesDrawRect: Bool = true, doneClosure: (() -> Void)?) {
                print("Record snapshot?", recordSnapshots);
                if (recordSnapshots || recordThisSnapshot) {
                    DispatchQueue.global(qos: .userInitiated).async {
                        Thread.sleep(forTimeInterval: 5.0);
                        DispatchQueue.main.async {
                            expect(view) == recordSnapshot(usesDrawRect: usesDrawRect);
                            doneClosure?();
                        }
                    }
                } else {
                    doneClosure?();
                }
            }
            
            beforeEach {
                tester().waitForAnimationsToFinish();
                if (controller != nil) {
                    waitUntil { done in
                        controller.dismiss(animated: false, completion: {
                            done();
                        });
                    }
                }
                TestHelpers.clearAndSetUpStack();
                window = UIWindow(frame: UIScreen.main.bounds);
                window.makeKeyAndVisible();
                UserDefaults.standard.serverMajorVersion = 5;
                UserDefaults.standard.serverMinorVersion = 4;
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.showMGRS = false;
                Server.setCurrentEventId(1);
                
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath("/api/events/1/observations/observationabc/attachments/attachmentabc")) { (request) -> HTTPStubsResponse in
                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
                controller = UINavigationController();
                window.rootViewController = controller;
            }
            
            afterEach {
                tester().waitForAnimationsToFinish();
                waitUntil { done in
                    controller.dismiss(animated: false, completion: {
                        done();
                    });
                }
                window?.resignKey();
                window.rootViewController = nil;
                controller = nil;
                view = nil;
                window = nil;
                TestHelpers.cleanUpStack();
                HTTPStubs.removeAllStubs();
            }
            
            it("initialize the ObservationViewCardCollectionViewController") {
                var completeTest = false;
                waitUntil(timeout: DispatchTimeInterval.seconds(5)) { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addUser(userId: "userabc") { (success: Bool, error: Error?) in
                            print("user added")
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")  { (success: Bool, error: Error?) in
                                print("user added to event")
                                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)  { (success: Bool, error: Error?) in
                                    print("observation added")
                                    done();
                                }
                            }
                        }
                    }
                }
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let observationViewController: ObservationViewCardCollectionViewController = ObservationViewCardCollectionViewController(observation: observation, scheme: MAGEScheme.scheme());
                controller.pushViewController(observationViewController, animated: true);
                
                view = window;
                
                tester().waitForAnimationsToFinish();
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Invalid snapshot")
                }
            }
            
            it("observation needs syncing") {
                var completeTest = false;
                waitUntil(timeout: DispatchTimeInterval.seconds(5)) { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addUser(userId: "userabc") { (success: Bool, error: Error?) in
                            print("user added")
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")  { (success: Bool, error: Error?) in
                                print("user added to event")
                                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)  { (success: Bool, error: Error?) in
                                    print("observation added")
                                    done();
                                }
                            }
                        }
                    }
                }
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                observation.dirty = true;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let observationViewController: ObservationViewCardCollectionViewController = ObservationViewCardCollectionViewController(observation: observation, scheme: MAGEScheme.scheme());
                controller.pushViewController(observationViewController, animated: true);
                
                view = window;
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Invalid snapshot")
                }
            }
            
            it("observation needs syncing and then gets pushed") {
                var completeTest = false;
                waitUntil(timeout: DispatchTimeInterval.seconds(5)) { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addUser(userId: "userabc") { (success: Bool, error: Error?) in
                            print("user added")
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")  { (success: Bool, error: Error?) in
                                print("user added to event")
                                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)  { (success: Bool, error: Error?) in
                                    print("observation added")
                                    done();
                                }
                            }
                        }
                    }
                }
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                observation.dirty = true;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let observationViewController: ObservationViewCardCollectionViewController = ObservationViewCardCollectionViewController(observation: observation, scheme: MAGEScheme.scheme());
                controller.pushViewController(observationViewController, animated: true);
                tester().waitForAnimationsToFinish();
                view = window;
                
                observation.dirty = false;
                observationViewController.didPush(observation, success: true, error: nil);
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Invalid snapshot")
                }
            }
            
            // tests to write
            
            // observation which does not have important set
            
            // observation with no attachments in the observation
            
            // observation with no primary or secondary field
            
            // observation with user who cannot set important
            
            // observation which is not favorited by the current user
            
            // observation actions - important, favorite, directions
            
            // click the favorite count button should show the users who favorited it
            
            // need to figure out what to do when a form exists but there are no fields filled out
            
            // edit button only shows up if user can edit
            
            // observation not synced
            
            // observation manual sync
            
            // obsrvation failed to sync
            
            // observation push delegate
        }
    }
}

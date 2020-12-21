//
//  MapViewControllerTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 12/9/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Nimble_Snapshots

import MagicalRecord

@testable import MAGE

class MapViewControllerTests: KIFSpec {
    
    override func spec() {
        
        describe("MapViewControllerTests") {
            let recordSnapshots = true;
            Nimble_Snapshots.setNimbleTolerance(0.1);
            
            var controller: UINavigationController!
            var view: UIView!
            var window: UIWindow!;
            
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
                NSManagedObject.mr_setDefaultBatchSize(1);
                window = UIWindow(frame: UIScreen.main.bounds);
                window.makeKeyAndVisible();
                UserDefaults.standard.mapType = 0;
//                UserDefaults.standard.set(0, forKey: "mapType");
                UserDefaults.standard.set(false, forKey: "showMGRS");
                UserDefaults.standard.synchronize();
                
                Server.setCurrentEventId(1);
                TimeFilter.setObservation(.all);

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
            }
            
            it("initialize the MapViewController") {
                var completeTest = false;
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addUser(userId: "user") { (success: Bool, error: Error?) in
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")  { (success: Bool, error: Error?) in
                                done();
                            }
                        }
                    }
                }
                UserDefaults.standard.setValue("user", forKey: "currentUserId");

                let mapViewController: MapViewController = MapViewController();
                controller.pushViewController(mapViewController, animated: true);
                
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
            
            it("initialize the MapViewController and create new observation") {
                var completeTest = false;
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addUser(userId: "user") { (success: Bool, error: Error?) in
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")  { (success: Bool, error: Error?) in
                                done();
                            }
                        }
                    }
                }
                UserDefaults.standard.setValue("user", forKey: "currentUserId");

                let mapViewController: MapViewController = MapViewController();
                let mockedLocationService = MockLocationService();
                mockedLocationService.mockedLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), altitude: 1625.8, horizontalAccuracy: 5.2, verticalAccuracy: 1.3, timestamp: Date());
                mapViewController.locationService = mockedLocationService;
                controller.pushViewController(mapViewController, animated: true);
                
                tester().waitForTappableView(withAccessibilityLabel: "New");
                tester().tapView(withAccessibilityLabel: "New");
                
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
            
            it("initialize the MapViewController and create new observation with no location") {
                var completeTest = false;
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addUser(userId: "user") { (success: Bool, error: Error?) in
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")  { (success: Bool, error: Error?) in
                                done();
                            }
                        }
                    }
                }
                UserDefaults.standard.setValue("user", forKey: "currentUserId");

                let mapViewController: MapViewController = MapViewController();
                let mockedLocationService = MockLocationService();
                mockedLocationService.mockedLocation = nil;
                mapViewController.locationService = mockedLocationService;
                controller.pushViewController(mapViewController, animated: true);
                
                tester().waitForTappableView(withAccessibilityLabel: "New");
                tester().tapView(withAccessibilityLabel: "New");
                
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
            
            it("initialize the MapViewController and create new empty observation") {
                var completeTest = false;
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addUser(userId: "user") { (success: Bool, error: Error?) in
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")  { (success: Bool, error: Error?) in
                                done();
                            }
                        }
                    }
                }
                UserDefaults.standard.setValue("user", forKey: "currentUserId");

                let mapViewController: MapViewController = MapViewController();
                let mockedLocationService = MockLocationService();
                mockedLocationService.mockedLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), altitude: 1625.8, horizontalAccuracy: 5.2, verticalAccuracy: 1.3, timestamp: Date());
                mapViewController.locationService = mockedLocationService;
                controller.pushViewController(mapViewController, animated: true);
                
                tester().waitForTappableView(withAccessibilityLabel: "New");
                tester().tapView(withAccessibilityLabel: "New");
                
                tester().waitForTappableView(withAccessibilityLabel: "Cancel");
                tester().tapView(withAccessibilityLabel: "Cancel");
                
                tester().tapView(withAccessibilityLabel: "Save");
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                let properties: [String: Any] = observation.properties! as! [String: Any];
                let forms: [[String: Any]] = properties["forms"] as! [[String: Any]];
                let geometry: SFGeometry = observation.getGeometry();
                let point: SFPoint = geometry as! SFPoint;
                expect(point.x).to(beCloseTo(-105.2677));
                expect(point.y).to(beCloseTo(40.008));
                expect(properties["accuracy"] as? Double).to(equal(5.2))
                expect(properties["delta"] as? Int).to(beGreaterThan(0));
                expect(properties["provider"] as? String).to(equal("gps"));
                expect(properties["timestamp"] as? String).toNot(beNil());
                expect(forms).toNot(beNil());
                expect(observation.isDirty()).to(beTrue());
                expect(observation.attachments).to(beEmpty());
                expect(observation.getFavoritesMap()).to(beEmpty());
                expect(geometry).to(beAnInstanceOf(SFPoint.self));
                expect(observation.eventId).to(equal(1));
                expect(observation.remoteId).to(beNil());
                
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
            
            it("initialize the MapViewController and create new empty observation with long press") {
                var completeTest = false;
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addUser(userId: "user") { (success: Bool, error: Error?) in
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")  { (success: Bool, error: Error?) in
                                done();
                            }
                        }
                    }
                }
                UserDefaults.standard.setValue("user", forKey: "currentUserId");
                
                let mapViewController: MapViewController = MapViewController();
                let mockedLocationService = MockLocationService();
                mockedLocationService.mockedLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), altitude: 1625.8, horizontalAccuracy: 5.2, verticalAccuracy: 1.3, timestamp: Date());
                mapViewController.locationService = mockedLocationService;
                controller.pushViewController(mapViewController, animated: true);
                
                tester().waitForView(withAccessibilityLabel: "map");
                mapViewController.mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), latitudinalMeters: 1, longitudinalMeters: 1), animated: false);
                mapViewController.mapView.setCenter(CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), animated: false);
                tester().longPressView(withAccessibilityLabel: "map", duration: 1.0);
                
                tester().waitForTappableView(withAccessibilityLabel: "Cancel");
                tester().tapView(withAccessibilityLabel: "Cancel");
                
                tester().tapView(withAccessibilityLabel: "Save");
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                let properties: [String: Any] = observation.properties! as! [String: Any];
                let forms: [[String: Any]] = properties["forms"] as! [[String: Any]];
                let geometry: SFGeometry = observation.getGeometry();
                expect(geometry).to(beAnInstanceOf(SFPoint.self));
                let point: SFPoint = geometry as! SFPoint;
                expect(point.x).to(beCloseTo(-105.2677));
                expect(point.y).to(beCloseTo(40.008));
                expect(properties["accuracy"] as? Double).to(equal(0))
                expect(properties["delta"] as? Int).to(equal(0));
                expect(properties["provider"] as? String).to(equal("manual"));
                expect(properties["timestamp"] as? String).toNot(beNil());
                expect(forms).toNot(beNil());
                expect(observation.isDirty()).to(beTrue());
                expect(observation.attachments).to(beEmpty());
                expect(observation.getFavoritesMap()).to(beEmpty());
                expect(observation.eventId).to(equal(1));
                expect(observation.remoteId).to(beNil());
                
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
            
            it("initialize the MapViewController and create an observation and view it") {
                var completeTest = false;
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addUser(userId: "user") { (success: Bool, error: Error?) in
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "user")  { (success: Bool, error: Error?) in
                                done();
                            }
                        }
                    }
                }
                
                UserDefaults.standard.setValue("user", forKey: "currentUserId");
                
                let mapViewController: MapViewController = MapViewController();
                let mockedLocationService = MockLocationService();
                mockedLocationService.mockedLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), altitude: 1625.8, horizontalAccuracy: 5.2, verticalAccuracy: 1.3, timestamp: Date());
                mapViewController.locationService = mockedLocationService;
                controller.pushViewController(mapViewController, animated: false);
                
                tester().waitForView(withAccessibilityLabel: "map");
                expect(mapViewController.mapView).toEventuallyNot(beNil());
                mapViewController.mapView.setRegion(MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), latitudinalMeters: 1, longitudinalMeters: 1), animated: false);
                mapViewController.mapView.setCenter(CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), animated: false);
                tester().longPressView(withAccessibilityLabel: "map", duration: 1.0);
                
                tester().waitForTappableView(withAccessibilityLabel: "Cancel");
                tester().tapView(withAccessibilityLabel: "Cancel");
                
                tester().tapView(withAccessibilityLabel: "timestamp");
                tester().waitForAnimationsToFinish();
                tester().waitForView(withAccessibilityLabel: "timestamp Date Picker");
                tester().selectDatePickerValue(["Nov 2", "7", "00", "AM"], with: .backwardFromCurrentValue);
                tester().tapView(withAccessibilityLabel: "Done");
                
                tester().tapView(withAccessibilityLabel: "Save");
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                let properties: [String: Any] = observation.properties! as! [String: Any];
                let forms: [[String: Any]] = properties["forms"] as! [[String: Any]];
                let geometry: SFGeometry = observation.getGeometry();
                expect(geometry).to(beAnInstanceOf(SFPoint.self));
                let point: SFPoint = geometry as! SFPoint;
                expect(point.x).to(beCloseTo(-105.2677));
                expect(point.y).to(beCloseTo(40.008));
                expect(properties["accuracy"] as? Double).to(equal(0))
                expect(properties["delta"] as? Int).to(equal(0));
                expect(properties["provider"] as? String).to(equal("manual"));
                expect(properties["timestamp"] as? String).toNot(beNil());
                expect(forms).toNot(beNil());
                expect(observation.isDirty()).to(beTrue());
                expect(observation.attachments).to(beEmpty());
                expect(observation.getFavoritesMap()).to(beEmpty());
                expect(observation.eventId).to(equal(1));
                expect(observation.remoteId).to(beNil());
                
                tester().waitForAnimationsToFinish();
                tester().waitForView(withAccessibilityLabel: "Observation \(observation.objectID)");
                tester().tapView(withAccessibilityLabel: "Observation \(observation.objectID)")
                
                tester().waitForTappableView(withAccessibilityLabel: "More Info");
                tester().tapView(withAccessibilityLabel: "More Info");
                
                TestHelpers.printAllAccessibilityLabelsInWindows();
                
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
            
            it("initialize the MapViewController and edit an observation") {
                var completeTest = false;
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addUser(userId: "userabc") { (success: Bool, error: Error?) in
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")  { (success: Bool, error: Error?) in
                                MageCoreDataFixtures.addObservationToEvent(eventId: 1) { (success: Bool, error: Error?) in
                                    
                                    done();
                                }
                            }
                        }
                    }
                }
                UserDefaults.standard.setValue("userabc", forKey: "currentUserId");

                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let mapViewController: MapViewController = MapViewController();
                let mockedLocationService = MockLocationService();
                mockedLocationService.mockedLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), altitude: 1625.8, horizontalAccuracy: 5.2, verticalAccuracy: 1.3, timestamp: Date());
                mapViewController.locationService = mockedLocationService;
                controller.pushViewController(mapViewController, animated: true);
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                
                tester().waitForView(withAccessibilityLabel: "Observation \(observation.objectID)");
                tester().tapView(withAccessibilityLabel: "Observation \(observation.objectID)")
                
                tester().waitForTappableView(withAccessibilityLabel: "More Info");
                tester().tapView(withAccessibilityLabel: "More Info");
                
                tester().waitForView(withAccessibilityLabel: "Edit");
                tester().tapView(withAccessibilityLabel: "Edit");
                
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
            
            it("initialize the MapViewController and cancel an edit") {
                var completeTest = false;
                waitUntil(timeout: DispatchTimeInterval.seconds(5)) { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addUser(userId: "userabc") { (success: Bool, error: Error?) in
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")  { (success: Bool, error: Error?) in
                                MageCoreDataFixtures.addObservationToEvent(eventId: 1) { (success: Bool, error: Error?) in
                                    
                                    done();
                                }
                            }
                        }
                    }
                }
                UserDefaults.standard.setValue("userabc", forKey: "currentUserId");

                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let mapViewController: MapViewController = MapViewController();
                let mockedLocationService = MockLocationService();
                mockedLocationService.mockedLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), altitude: 1625.8, horizontalAccuracy: 5.2, verticalAccuracy: 1.3, timestamp: Date());
                mapViewController.locationService = mockedLocationService;
                controller.pushViewController(mapViewController, animated: true);
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                
                tester().waitForView(withAccessibilityLabel: "Observation \(observation.objectID)");
                tester().tapView(withAccessibilityLabel: "Observation \(observation.objectID)")
                
                tester().waitForTappableView(withAccessibilityLabel: "More Info");
                tester().tapView(withAccessibilityLabel: "More Info");
                
                tester().waitForView(withAccessibilityLabel: "Edit");
                tester().tapView(withAccessibilityLabel: "Edit");
                
                tester().waitForAnimationsToFinish();
                tester().waitForView(withAccessibilityLabel: "Cancel");
                tester().tapView(withAccessibilityLabel: "Cancel");
                
                tester().waitForAnimationsToFinish();
                tester().waitForView(withAccessibilityLabel: "Yes, Discard");
                tester().tapView(withAccessibilityLabel: "Yes, Discard");
                
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
            
            it("initialize the MapViewController and save an edit") {
                var completeTest = false;
                waitUntil { done in
                    MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm") { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addUser(userId: "userabc") { (success: Bool, error: Error?) in
                            MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")  { (success: Bool, error: Error?) in
                                MageCoreDataFixtures.addObservationToEvent(eventId: 1) { (success: Bool, error: Error?) in
                                    
                                    done();
                                }
                            }
                        }
                    }
                }
                
                UserDefaults.standard.setValue("userabc", forKey: "currentUserId");

                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let mapViewController: MapViewController = MapViewController();
                let mockedLocationService = MockLocationService();
                mockedLocationService.mockedLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.008, longitude: -105.2677), altitude: 1625.8, horizontalAccuracy: 5.2, verticalAccuracy: 1.3, timestamp: Date());
                mapViewController.locationService = mockedLocationService;
                controller.pushViewController(mapViewController, animated: true);
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                
                tester().waitForView(withAccessibilityLabel: "Observation \(observation.objectID)");
                tester().tapView(withAccessibilityLabel: "Observation \(observation.objectID)")
                
                tester().waitForTappableView(withAccessibilityLabel: "More Info");
                tester().tapView(withAccessibilityLabel: "More Info");
                
                tester().waitForView(withAccessibilityLabel: "Edit");
                tester().tapView(withAccessibilityLabel: "Edit");
                
                tester().waitForAnimationsToFinish();
                TestHelpers.printAllAccessibilityLabelsInWindows();
                tester().waitForView(withAccessibilityLabel: "expand");
                tester().tapView(withAccessibilityLabel: "expand");
                tester().waitForView(withAccessibilityLabel: "field2");
                tester().clearText(fromAndThenEnterText: "new description", intoViewWithAccessibilityLabel: "field2");
                tester().tapView(withAccessibilityLabel: "Done");
                tester().waitForView(withAccessibilityLabel: "Save");
                tester().tapView(withAccessibilityLabel: "Save");
                
                tester().waitForAnimationsToFinish();
                
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
        }
    }
}

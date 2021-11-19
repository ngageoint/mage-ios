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
//import Nimble_Snapshots
import OHHTTPStubs
import MagicalRecord

@testable import MAGE

class ObservationViewCardCollectionViewControllerTests: KIFSpec {
    
    override func spec() {
        
        describe("ObservationViewCardCollectionViewControllerTests") {
//            Nimble_Snapshots.setNimbleTolerance(0.1);
            
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
            
//            func maybeRecordSnapshot(_ view: UIView, recordThisSnapshot: Bool = false, usesDrawRect: Bool = true, doneClosure: (() -> Void)?) {
//                print("Record snapshot?", recordSnapshots);
//                if (recordSnapshots || recordThisSnapshot) {
//                    DispatchQueue.global(qos: .userInitiated).async {
//                        Thread.sleep(forTimeInterval: 5.0);
//                        DispatchQueue.main.async {
//                            expect(view) == recordSnapshot(usesDrawRect: usesDrawRect);
//                            doneClosure?();
//                        }
//                    }
//                } else {
//                    doneClosure?();
//                }
//            }
            
            beforeEach {
                
                if (controller != nil) {
                    waitUntil { done in
                        controller.dismiss(animated: false, completion: {
                            done();
                        });
                    }
                }
                TestHelpers.clearAndSetUpStack();
                if (view != nil) {
                    for subview in view.subviews {
                        subview.removeFromSuperview();
                    }
                }
                window = TestHelpers.getKeyWindowVisible();
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
                NSManagedObject.mr_setDefaultBatchSize(0);
                
                ObservationPushService.singleton.stop();
            }
            
            afterEach {
                for subview in view.subviews {
                    subview.removeFromSuperview();
                }
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
                TestHelpers.clearAndSetUpStack();
                HTTPStubs.removeAllStubs();
                NSManagedObject.mr_setDefaultBatchSize(20);
            }
            
            it("initialize the ObservationViewCardCollectionViewController") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let observationViewController: ObservationViewCardCollectionViewController = ObservationViewCardCollectionViewController(observation: observation, scheme: MAGEScheme.scheme());
                controller.pushViewController(observationViewController, animated: true);
                
                view = window;
                
//                maybeRecordSnapshot(view, doneClosure: {
//                    completeTest = true;
//                })
//
//                if (recordSnapshots) {
//                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
//                } else {
//                    expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Invalid snapshot")
//                }
            }
            
            it("observation needs syncing") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                observation.dirty = true;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let observationViewController: ObservationViewCardCollectionViewController = ObservationViewCardCollectionViewController(observation: observation, scheme: MAGEScheme.scheme());
                controller.pushViewController(observationViewController, animated: true);
                
                view = window;
                
//                maybeRecordSnapshot(view, doneClosure: {
//                    completeTest = true;
//                })
//
//                if (recordSnapshots) {
//                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
//                } else {
//                    expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Invalid snapshot")
//                }
            }
            
            it("observation needs syncing and then gets pushed") {
                MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                observation.dirty = true;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let observationViewController: ObservationViewCardCollectionViewController = ObservationViewCardCollectionViewController(observation: observation, scheme: MAGEScheme.scheme());
                controller.pushViewController(observationViewController, animated: true);
                
                view = window;
                
                observation.dirty = false;
                observationViewController.didPush(observation: observation, success: true, error: nil);
                
//                maybeRecordSnapshot(view, doneClosure: {
//                    completeTest = true;
//                })
//                
//                if (recordSnapshots) {
//                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
//                } else {
//                    expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Invalid snapshot")
//                }
            }
            
            it("location copied from geometry form field") {
                Server.setCurrentEventId(2);

                MageCoreDataFixtures.addEvent(remoteId: 2, name: "Event", formsJsonFile: "geometryField")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 2, userId: "userabc")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson(filename: "geometryObservations");
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                observation.dirty = true;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let observationViewController: ObservationViewCardCollectionViewController = ObservationViewCardCollectionViewController(observation: observation, scheme: MAGEScheme.scheme());
                controller.pushViewController(observationViewController, animated: true);
                
                view = window;
                
                
                
                tester().scrollView(withAccessibilityIdentifier: "card scroll", byFractionOfSizeHorizontal: 0, vertical: 1.0)
                tester().tapView(withAccessibilityLabel: "location field1", traits: UIAccessibilityTraits(arrayLiteral: .button));
                tester().waitForView(withAccessibilityLabel: "Location copied to clipboard");
            }
            
            it("initiate form reorder") {
                Server.setCurrentEventId(2);
                
                MageCoreDataFixtures.addEvent(remoteId: 2, name: "Event", formsJsonFile: "twoForms")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 2, userId: "userabc")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson(filename: "twoFormsObservations");
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                observation.dirty = true;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let observationViewController: ObservationViewCardCollectionViewController = ObservationViewCardCollectionViewController(observation: observation, scheme: MAGEScheme.scheme());
                controller.pushViewController(observationViewController, animated: true);
                
                view = window;
                
                
                tester().tapView(withAccessibilityLabel: "more");
                
                tester().waitForView(withAccessibilityLabel: "Delete Observation");
                tester().waitForView(withAccessibilityLabel: "Edit Observation");
                tester().waitForView(withAccessibilityLabel: "Reorder Forms");
                tester().waitForView(withAccessibilityLabel: "View Other Observations");
                
                tester().tapView(withAccessibilityLabel: "Reorder Forms");
                expect(UIApplication.getTopViewController()).toEventually(beAnInstanceOf(ObservationFormReorder.self));
            }
            
            it("form reorder shouldn't exist for one form observations") {
                Server.setCurrentEventId(2);
                
               MageCoreDataFixtures.addEvent(remoteId: 2, name: "Event", formsJsonFile: "geometryField")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 2, userId: "userabc")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson(filename: "geometryObservations");
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                observation.dirty = true;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                controller.pushViewController(UIViewController(), animated: false);
                var observationViewController: ObservationViewCardCollectionViewController? = ObservationViewCardCollectionViewController(observation: observation, scheme: MAGEScheme.scheme());
                controller.pushViewController(observationViewController!, animated: true);
                
                view = window;
                
                
                tester().tapView(withAccessibilityLabel: "more");
                
                tester().waitForView(withAccessibilityLabel: "Delete Observation");
                tester().waitForView(withAccessibilityLabel: "Edit Observation");
                tester().waitForView(withAccessibilityLabel: "View Other Observations");
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Reorder Forms");
                tester().tapView(withAccessibilityLabel: "Cancel");
                expect(UIApplication.getTopViewController()).toEventually(beAnInstanceOf(ObservationViewCardCollectionViewController.self));
                controller.popToRootViewController(animated: false);
                expect(UIApplication.getTopViewController()).toEventuallyNot(beAnInstanceOf(ObservationViewCardCollectionViewController.self));
                
                observationViewController = nil;
            }
            
            it("delete observation") {
                Server.setCurrentEventId(2);
                
                
                MageCoreDataFixtures.addEvent(remoteId: 2, name: "Event", formsJsonFile: "geometryField")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 2, userId: "userabc")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson(filename: "geometryObservations");
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                observation.dirty = true;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                controller.pushViewController(UIViewController(), animated: true);
                let observationViewController: ObservationViewCardCollectionViewController = ObservationViewCardCollectionViewController(observation: observation, scheme: MAGEScheme.scheme());
                controller.pushViewController(observationViewController, animated: true);
                
                view = window;
                
                
                tester().tapView(withAccessibilityLabel: "more");
                
                tester().tapView(withAccessibilityLabel: "Delete Observation");
                tester().tapView(withAccessibilityLabel: "Yes, Delete");
                
                expect(controller.topViewController).toEventuallyNot(beAnInstanceOf(ObservationViewCardCollectionViewController.self))
            }
            
            it("view attachment") {
                Server.setCurrentEventId(2);
                
                
                MageCoreDataFixtures.addEvent(remoteId: 2, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 2, userId: "userabc")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                observation.dirty = true;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let observationViewController: ObservationViewCardCollectionViewController = ObservationViewCardCollectionViewController(observation: observation, scheme: MAGEScheme.scheme());
                controller.pushViewController(observationViewController, animated: true);
                
                view = window;
                

                TestHelpers.printAllAccessibilityLabelsInWindows();
                
                tester().tapItem(at: IndexPath(item: 0, section: 0), inCollectionViewWithAccessibilityIdentifier: "Attachment Collection");
                expect(controller.topViewController).toEventually(beAnInstanceOf(ImageAttachmentViewController.self));
                tester().tapView(withAccessibilityLabel: "Observation");
                expect(controller.topViewController).toEventually(beAnInstanceOf(ObservationViewCardCollectionViewController.self));
            }
            
            it("view favorites") {
                Server.setCurrentEventId(2);
                
                MageCoreDataFixtures.addEvent(remoteId: 2, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 2, userId: "userabc")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                observation.dirty = true;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let observationViewController: ObservationViewCardCollectionViewController = ObservationViewCardCollectionViewController(observation: observation, scheme: MAGEScheme.scheme());
                controller.pushViewController(observationViewController, animated: true);
                
                view = window;
                
                
                TestHelpers.printAllAccessibilityLabelsInWindows();
                
                tester().tapView(withAccessibilityLabel: "show favorites");
                expect(controller.topViewController).toEventually(beAnInstanceOf(LocationsTableViewController.self));
            }
            
            it("favorite the observation") {
                Server.setCurrentEventId(2);
                
                MageCoreDataFixtures.addEvent(remoteId: 2, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 2, userId: "userabc")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                observation.dirty = true;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let scheme = MAGEScheme.scheme();
                let observationViewController: ObservationViewCardCollectionViewController = ObservationViewCardCollectionViewController(observation: observation, scheme: scheme);
                controller.pushViewController(observationViewController, animated: true);
                
                view = window;
                
                expect((viewTester().usingLabel("favorite").view as! MDCButton).imageTintColor(for: .normal)).to(equal(MDCPalette.green.accent700));
                
                tester().tapView(withAccessibilityLabel: "favorite");
                
                expect((viewTester().usingLabel("favorite").view as! MDCButton).imageTintColor(for: .normal)).toEventually(equal(scheme.colorScheme.onSurfaceColor.withAlphaComponent(0.6)));
            }
            
            it("get directions") {
                Server.setCurrentEventId(2);
                
                MageCoreDataFixtures.addEvent(remoteId: 2, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 2, userId: "userabc")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                observation.dirty = true;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let scheme = MAGEScheme.scheme();
                let observationViewController: ObservationViewCardCollectionViewController = ObservationViewCardCollectionViewController(observation: observation, scheme: scheme);
                controller.pushViewController(observationViewController, animated: true);
                
                view = window;
                
                tester().tapView(withAccessibilityLabel: "directions");
                
                tester().waitForView(withAccessibilityLabel: "Apple Maps");
                tester().waitForView(withAccessibilityLabel: "Google Maps");
                tester().tapView(withAccessibilityLabel: "Cancel");
            }
            
            it("update important and then remove it") {
                Server.setCurrentEventId(2);
                
                MageCoreDataFixtures.addEvent(remoteId: 2, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 2, userId: "userabc")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                observation.dirty = true;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let scheme = MAGEScheme.scheme();
                let observationViewController: ObservationViewCardCollectionViewController = ObservationViewCardCollectionViewController(observation: observation, scheme: scheme);
                controller.pushViewController(observationViewController, animated: true);
                
                view = window;
                
                
                expect((viewTester().usingLabel("important").view as! MDCButton).imageTintColor(for: .normal)).to(equal(MDCPalette.orange.accent400));
                
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Update Important");
                tester().tapView(withAccessibilityLabel: "important");
                
                tester().waitForView(withAccessibilityLabel: "Important Description");
                tester().waitForView(withAccessibilityLabel: "Update Important");
                
                tester().expect(viewTester().usingLabel("Important Description").view, toContainText: "This is important");
                tester().clearText(fromAndThenEnterText: "New important", intoViewWithAccessibilityLabel: "Important Description");
                
                tester().tapView(withAccessibilityLabel: "Update Important");
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Important Description");
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Update Important");
                tester().expect(viewTester().usingLabel("important reason").view, toContainText: "New important")
                
                tester().tapView(withAccessibilityLabel: "important");
                
                tester().waitForView(withAccessibilityLabel: "Important Description");
                tester().waitForView(withAccessibilityLabel: "Update Important");
                
                tester().tapView(withAccessibilityLabel: "Remove")
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Important Description");
                tester().waitForAbsenceOfView(withAccessibilityLabel: "Update Important");
                tester().waitForAbsenceOfView(withAccessibilityLabel: "important reason");
            }
            
            it("edit the observation") {
                Server.setCurrentEventId(2);
                
                
                MageCoreDataFixtures.addEvent(remoteId: 2, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 2, userId: "userabc")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                observation.dirty = true;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let scheme = MAGEScheme.scheme();
                let observationViewController: ObservationViewCardCollectionViewController = ObservationViewCardCollectionViewController(observation: observation, scheme: scheme);
                controller.pushViewController(observationViewController, animated: true);
                
                view = window;
                
                
                tester().expect(viewTester().usingLabel("field2 Value").view, toContainText: "Test");
                
                
                tester().tapView(withAccessibilityLabel: "more");
                
                tester().tapView(withAccessibilityLabel: "Edit Observation");
                
                tester().clearText(fromAndThenEnterText: "the description", intoViewWithAccessibilityLabel: "field2");
                tester().tapView(withAccessibilityLabel: "Done");
                tester().tapView(withAccessibilityLabel: "Save");
                
                expect(controller.topViewController).toEventually(beAnInstanceOf(ObservationViewCardCollectionViewController.self));
                tester().expect(viewTester().usingLabel("field2 Value").view, toContainText: "the description");
            }
            
            it("cancel editing the observation") {
                Server.setCurrentEventId(2);
                
                
                MageCoreDataFixtures.addEvent(remoteId: 2, name: "Event", formsJsonFile: "oneForm")
                MageCoreDataFixtures.addUser(userId: "userabc")
                MageCoreDataFixtures.addUserToEvent(eventId: 2, userId: "userabc")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
                
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                observation.dirty = true;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let scheme = MAGEScheme.scheme();
                var observationViewController: ObservationViewCardCollectionViewController? = ObservationViewCardCollectionViewController(observation: observation, scheme: scheme);
                controller.pushViewController(observationViewController!, animated: true);
                
                view = window;
                
                
                tester().expect(viewTester().usingLabel("field2 Value").view, toContainText: "Test");
                
                
                tester().tapView(withAccessibilityLabel: "more");
                tester().waitForTappableView(withAccessibilityLabel: "Edit Observation");
                tester().tapView(withAccessibilityLabel: "Edit Observation");
                tester().waitForAnimationsToFinish()
                tester().clearText(fromAndThenEnterText: "the description", intoViewWithAccessibilityLabel: "field2");
                tester().tapView(withAccessibilityLabel: "Done");
                tester().tapView(withAccessibilityLabel: "Cancel");
                tester().tapView(withAccessibilityLabel: "Yes, Discard");

                expect(controller.topViewController).toEventually(beAnInstanceOf(ObservationViewCardCollectionViewController.self));
                tester().expect(viewTester().usingLabel("field2 Value").view, toContainText: "Test");
                waitUntil { done in
                    controller.dismiss(animated: false) {
                        observationViewController = nil;
                        done();
                    }
                }
//                observationViewController = nil;
            }
        }
    }
}

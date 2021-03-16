//
//  ObservationTableViewControllerTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 3/16/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Kingfisher
import OHHTTPStubs

@testable import MAGE

@available(iOS 13.0, *)

class ObservationTableViewControllerTests: KIFSpec {
    
    override func spec() {
        
        fdescribe("ObservationTableViewControllerTests") {
            
            var window: UIWindow?;
            var view: ObservationTableViewController?;
            var navigationController: UINavigationController?;
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();
                
                window = UIWindow(frame: UIScreen.main.bounds);
                
                UserDefaults.standard.baseServerUrl = "https://magetest";
                
                navigationController = UINavigationController();
                window?.rootViewController = navigationController;
                window?.makeKeyAndVisible();
                
                waitUntil { done in
                    MageCoreDataFixtures.addEvent { (success: Bool, error: Error?) in
                        Server.setCurrentEventId(1);
                        done();
                    }
                }
                NSManagedObject.mr_setDefaultBatchSize(0);
            }
            
            afterEach {
                navigationController?.viewControllers = [];
                window?.rootViewController?.dismiss(animated: false, completion: nil);
                window?.rootViewController = nil;
                navigationController = nil;
                view = nil;
                window?.resignKey();
                window = nil;
                TestHelpers.clearAndSetUpStack();
                tester().waitForAnimationsToFinish();
                HTTPStubs.removeAllStubs();
                NSManagedObject.mr_setDefaultBatchSize(20);
            }
            
            it("should load an empty ObservationTableViewController") {
                view = ObservationTableViewController(scheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                expect(UIApplication.getTopViewController()).toEventually(beAnInstanceOf(ObservationTableViewController.self));
                
                expect(view?.observationDataStore.numberOfSections(in: (view?.tableView)!)).to(be(0));
            }
            
            it("should load an ObservationTableViewController with one item") {
                waitUntil(timeout: DispatchTimeInterval.seconds(2)) { done in
                    MageCoreDataFixtures.addUser(userId: "userabc") { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")  { (success: Bool, error: Error?) in
                            let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                            MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)  { (success: Bool, error: Error?) in
                                done();
                            }
                        }
                    }
                }
                
                UserDefaults.standard.observationTimeFilter = TimeFilterType.all;
                
                view = ObservationTableViewController(scheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                tester().waitForAnimationsToFinish();
                expect(UIApplication.getTopViewController()).to(beAnInstanceOf(ObservationTableViewController.self));
                
                expect(view?.observationDataStore.numberOfSections(in: (view?.tableView)!)).to(be(1));
                expect(view?.tableView.numberOfRows(inSection: 0)).to(be(1));
            }
            
            it("should load an empty ObservationTableViewController and add one item") {
                waitUntil(timeout: DispatchTimeInterval.seconds(2)) { done in
                    MageCoreDataFixtures.addUser(userId: "userabc") { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")  { (success: Bool, error: Error?) in
                            done();
                        }
                    }
                }
                
                UserDefaults.standard.observationTimeFilter = TimeFilterType.all;
                
                view = ObservationTableViewController(scheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                tester().waitForAnimationsToFinish();
                expect(UIApplication.getTopViewController()).to(beAnInstanceOf(ObservationTableViewController.self));
                
                expect(view?.observationDataStore.numberOfSections(in: (view?.tableView)!)).to(be(0));
                
                waitUntil { done in
                    let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                    MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)  { (success: Bool, error: Error?) in
                        done();
                    }
                }
                
                expect(view?.observationDataStore.numberOfSections(in: (view?.tableView)!)).to(be(1));
                expect(view?.tableView.numberOfRows(inSection: 0)).to(be(1));
            }
        }
    }
}

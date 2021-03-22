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
        
        describe("ObservationTableViewControllerTests") {
            
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
                
                MageCoreDataFixtures.addEvent();
                Server.setCurrentEventId(1);
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
                HTTPStubs.removeAllStubs();
                NSManagedObject.mr_setDefaultBatchSize(20);
            }
            
            it("should load an empty ObservationTableViewController") {
                view = ObservationTableViewController(scheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                expect(UIApplication.getTopViewController()).toEventually(beAnInstanceOf(ObservationTableViewController.self));
                
                expect(view?.observationDataStore.numberOfSections(in: (view?.tableView)!)).toEventually(equal(0));
            }
            
            it("should load an ObservationTableViewController with one item") {
                MageCoreDataFixtures.addUser(userId: "userabc");
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson);
                
                UserDefaults.standard.observationTimeFilter = TimeFilterType.all;
                
                view = ObservationTableViewController(scheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                expect(UIApplication.getTopViewController()).to(beAnInstanceOf(ObservationTableViewController.self));
                tester().waitForCell(at: IndexPath(row: 0, section: 0), in: view?.tableView);
                expect(view?.observationDataStore.numberOfSections(in: (view?.tableView)!)).to(equal(1));
                expect(view?.tableView.numberOfRows(inSection: 0)).to(equal(1));
            }
            
            it("should load an empty ObservationTableViewController and add one item") {
                MageCoreDataFixtures.addUser(userId: "userabc");
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                
                UserDefaults.standard.observationTimeFilter = TimeFilterType.all;
                
                view = ObservationTableViewController(scheme: MAGEScheme.scheme());
                navigationController?.pushViewController(view!, animated: false);
                expect(UIApplication.getTopViewController()).to(beAnInstanceOf(ObservationTableViewController.self));
                
                expect(view?.observationDataStore.numberOfSections(in: (view?.tableView)!)).toEventually(equal(0));
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson);
                expect(view?.observationDataStore.numberOfSections(in: (view?.tableView)!)).toEventually(equal(1));
                expect(view?.tableView.numberOfRows(inSection: 0)).to(equal(1));
            }
        }
    }
}

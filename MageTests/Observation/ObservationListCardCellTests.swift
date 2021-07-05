//
//  ObservationListCardCellTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 5/30/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Nimble_Snapshots
import Kingfisher
import OHHTTPStubs

@testable import MAGE

class ObservationListCardCellTests: KIFSpec {
    
    override func spec() {
        
        describe("ObservationListCardCellTests") {
            
            let recordSnapshots = false;
            
            var window: UIWindow?;
            var viewController: ObservationTableViewController?;
            var view: UIView?;
            var navigationController: UINavigationController?;
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();
                                
                UserDefaults.standard.baseServerUrl = "https://magetest";
                
                navigationController = UINavigationController();
                
                window = TestHelpers.getKeyWindowVisible();
                window!.rootViewController = navigationController;
                
                MageCoreDataFixtures.addEvent();
                Server.setCurrentEventId(1);
                NSManagedObject.mr_setDefaultBatchSize(0);
                
                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath("/api/events/1/observations/observationabc/attachments/attachmentabc")) { (request) -> HTTPStubsResponse in
                    let image: UIImage = TestHelpers.createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 500, height: 500))
                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
                }
                
            }
            
            afterEach {
                navigationController?.viewControllers = [];
                window?.rootViewController?.dismiss(animated: false, completion: nil);
                window?.rootViewController = nil;
                navigationController = nil;
                viewController = nil;
                TestHelpers.clearAndSetUpStack();
                HTTPStubs.removeAllStubs();

                NSManagedObject.mr_setDefaultBatchSize(20);
            }
                        
            it("should load an ObservationListCardCell") {
                MageCoreDataFixtures.addUser(userId: "userabc");
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson);
                UserDefaults.standard.currentUserId = "userabc";
                UserDefaults.standard.observationTimeFilter = TimeFilterType.all;
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                
                viewController = ObservationTableViewController(scheme: MAGEScheme.scheme());
                navigationController?.pushViewController(viewController!, animated: false);
                expect(UIApplication.getTopViewController()).to(beAnInstanceOf(ObservationTableViewController.self));
                tester().waitForCell(at: IndexPath(row: 0, section: 0), in: viewController?.tableView);
                expect(viewController?.observationDataStore.numberOfSections(in: (viewController?.tableView)!)).to(equal(1));
                expect(viewController?.tableView.numberOfRows(inSection: 0)).to(equal(1));
                
                tester().waitForView(withAccessibilityLabel: "attachment \(observation.attachments?.first?.name ?? "") loaded")

                view = viewTester().usingLabel("observation card \(observation.objectID.uriRepresentation().absoluteString)").view
                if (!recordSnapshots) {
                    expect(view).to(haveValidSnapshot(usesDrawRect: true))
                } else {
                    expect(view) == recordSnapshot(usesDrawRect: true);
                }
            }
        }
    }
}

//
//  ObservationBottomSheetTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 5/30/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
//import Nimble_Snapshots
import Kingfisher
import OHHTTPStubs

@testable import MAGE

class ObservationBottomSheetTests: KIFSpec {
    
    override func spec() {
        
        describe("ObservationBottomSheetTests") {
            var window: UIWindow?;
            var viewController: MageBottomSheetViewController?;
            var navigationController: UINavigationController?;
            
            var stackSetup = false;
            beforeEach {
                if (!stackSetup) {
                    UserDefaults.standard.baseServerUrl = "https://magetest";
                    
                    navigationController = UINavigationController();
                    TestHelpers.clearAndSetUpStack();
                    stackSetup = true;
                }
                
                window = TestHelpers.getKeyWindowVisible();
                window!.rootViewController = navigationController;

                MageCoreDataFixtures.clearAllData()
                
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
                MageCoreDataFixtures.clearAllData()
                HTTPStubs.removeAllStubs();
                
                NSManagedObject.mr_setDefaultBatchSize(20);
            }
            
            it("should load an ObservationBottomSheetController") {
                MageCoreDataFixtures.addUser(userId: "userabc");
                MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
                let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
                MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson);
                
                UserDefaults.standard.currentUserId = "userabc";
                
                let observations = Observation.mr_findAll();
                expect(observations?.count).to(equal(1));
                let observation: Observation = observations![0] as! Observation;
                NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
                let delegate = MockObservationActionsDelegate();
                
                viewController = MageBottomSheetViewController(items: [BottomSheetItem(item: observation, actionDelegate: delegate, annotationView: nil)], mapView: nil, scheme: MAGEScheme.scheme());
                viewController?.preferredContentSize = CGSize(width: viewController?.preferredContentSize.width ?? 0.0,
                                                              height: observation.isImportant ? 260 : 220);
                
                var bottomSheetLoaded = false;
                let bottomSheet = MDCBottomSheetController(contentViewController: viewController!);
                navigationController?.present(bottomSheet, animated: false, completion: {
                    bottomSheetLoaded = true
                });
                expect(bottomSheetLoaded).toEventually(beTrue())
                TestHelpers.printAllAccessibilityLabelsInWindows();

                expect(UIApplication.getTopViewController()).toEventually(beAnInstanceOf(MDCBottomSheetController.self));
            }
        }
    }
}

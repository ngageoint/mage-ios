//
//  UserViewControllerTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 7/13/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
//import Nimble_Snapshots
import MagicalRecord
import OHHTTPStubs

@testable import MAGE

class UserViewControllerTests: KIFSpec {
    
//    override func spec() {
//        
//        describe("UserViewController") {
//        
//            var controller: UserViewController!
//            var window: UIWindow!;
//            
//            func createGradientImage(startColor: UIColor, endColor: UIColor, size: CGSize = CGSize(width: 1, height: 1)) -> UIImage {
//                let rect = CGRect(origin: .zero, size: size)
//                let gradientLayer = CAGradientLayer()
//                gradientLayer.frame = rect
//                gradientLayer.colors = [startColor.cgColor, endColor.cgColor]
//                
//                UIGraphicsBeginImageContext(gradientLayer.bounds.size)
//                gradientLayer.render(in: UIGraphicsGetCurrentContext()!)
//                let image = UIGraphicsGetImageFromCurrentImageContext()
//                UIGraphicsEndImageContext()
//                guard let cgImage = image?.cgImage else { return UIImage() }
//                return UIImage(cgImage: cgImage)
//            }
//            
//            beforeEach {
//                
//                TestHelpers.clearAndSetUpStack();
//                MageCoreDataFixtures.quietLogging();
//                
//                window = TestHelpers.getKeyWindowVisible();
//                
//                Server.setCurrentEventId(1);
//                UserDefaults.standard.mapType = 0;
//                UserDefaults.standard.locationDisplay = .latlng;
//                
//                stub(condition: isMethodGET() && isHost("magetest") && isScheme("https") && isPath("/api/events/1/observations/observationabc/attachments/attachmentabc")) { (request) -> HTTPStubsResponse in
//                    let image: UIImage = createGradientImage(startColor: .blue, endColor: .red, size: CGSize(width: 500, height: 500))
//                    return HTTPStubsResponse(data: image.pngData()!, statusCode: 200, headers: ["Content-Type": "image/png"]);
//                }
//            }
//            
//            afterEach {
//                controller.dismiss(animated: false, completion: nil);
//                window.rootViewController = nil;
//                controller = nil;
//                TestHelpers.clearAndSetUpStack();
//                HTTPStubs.removeAllStubs();
//            }
//            
//            it("user view") {
//                MageCoreDataFixtures.addEvent()
//                MageCoreDataFixtures.addUser()
//                MageCoreDataFixtures.addLocation()
//                MageCoreDataFixtures.addObservationToEvent()
//                
//                UserDefaults.standard.currentUserId = "userabc2";
//                
//                MageCoreDataFixtures.addUser(userId: "userabc2")
//                MageCoreDataFixtures.addUserToEvent(userId: "userabc2")
//                
//                let user: User = User.mr_findFirst(byAttribute: "remoteId", withValue: "userabc")!;
//                
//                controller = UserViewController(user: user, scheme: MAGEScheme.scheme());
//                let nc = UINavigationController(rootViewController: controller);
//                window.rootViewController = nc;
//                
//                tester().expect(viewTester().usingLabel("name").view, toContainText: "User ABC");
//                tester().expect(viewTester().usingLabel("location").view, toContainText: "40.10850, -104.36780  GPS +/- 266.16m");
//                tester().expect(viewTester().usingLabel("303-555-5555").view, toContainText: "303-555-5555");
//                tester().expect(viewTester().usingLabel("userabc@test.com").view, toContainText: "userabc@test.com");
//                
//                tester().tapView(withAccessibilityLabel: "location button", traits: UIAccessibilityTraits(arrayLiteral: .button));
//                tester().waitForView(withAccessibilityLabel: "Location 40.00850, -105.26780 copied to clipboard");
//                TestHelpers.printAllAccessibilityLabelsInWindows()
//                tester().tapView(withAccessibilityLabel: "favorite", traits: UIAccessibilityTraits(arrayLiteral: .button));
//                tester().wait(forTimeInterval: 0.5);
//                expect((viewTester().usingLabel("favorite").view as! MDCButton).imageTintColor(for:.normal)).to(be(MDCPalette.green.accent700));
//
//                let directionsExpectation = self.expectation(forNotification: .DirectionsToItem, object: nil, handler: nil)
//                tester().tapView(withAccessibilityLabel: "directions", traits: UIAccessibilityTraits(arrayLiteral: .button));
//                let result: XCTWaiter.Result = XCTWaiter.wait(for: [directionsExpectation], timeout: 5.0)
//                XCTAssertEqual(result, .completed)
//
//                let observation: Observation = ((user.observations)?.first)!;
//                let attachment: Attachment = ((observation.attachments)?.first!)! ;
//                TestHelpers.printAllAccessibilityLabelsInWindows()
//                tester().waitForView(withAccessibilityLabel: "attachment \(attachment.name ?? "") loaded")
//                tester().tapView(withAccessibilityLabel: "attachment \(attachment.name ?? "") loaded");
//                expect(nc.topViewController).toEventually(beAnInstanceOf(ImageAttachmentViewController.self));
//                tester().tapView(withAccessibilityLabel: "User ABC");
//                expect(nc.topViewController).toEventually(beAnInstanceOf(UserViewController.self));
//                let tableView: UITableView = viewTester().usingIdentifier("user observations").view as! UITableView;
//                let cell: ObservationListCardCell = tester().waitForCell(at: IndexPath(row: 0, section: 0), in: tableView) as! ObservationListCardCell;
//                let card: MDCCard = viewTester().usingLabel("observation card \(observation.objectID.uriRepresentation().absoluteString)").view as! MDCCard;
//                cell.tap(card);
//                expect(nc.topViewController).toEventually(beAnInstanceOf(ObservationViewCardCollectionViewController.self));
//                tester().tapView(withAccessibilityLabel: "User ABC");
//                expect(nc.topViewController).toEventually(beAnInstanceOf(UserViewController.self));
//            }
//        }
//    }
}

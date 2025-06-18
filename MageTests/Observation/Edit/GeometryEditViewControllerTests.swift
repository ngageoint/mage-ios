//
//  GeometryEditViewControllerTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 6/10/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
//import Nimble_Snapshots

@testable import MAGE

class GeometryEditViewControllerTests: KIFSpec {
    
    override func spec() {
        
        describe("GeometryEditViewController") {
            var geometryEditViewController: GeometryEditViewController?
            let navController = UINavigationController();

            var window: UIWindow!;
            var field: [String: Any]!

            beforeEach {
                TestHelpers.clearAndSetUpStack();

                MageCoreDataFixtures.clearAllData();
                TestHelpers.resetUserDefaults();
                window = TestHelpers.getKeyWindowVisible();
                window.rootViewController = navController;
                
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.locationDisplay = .latlng;
                UserDefaults.standard.serverMajorVersion = 6;
                UserDefaults.standard.serverMinorVersion = 0;
                
                field = [
                    "title": "Field Title",
                    "name": "field8",
                    "type": "geometry",
                    "id": 8
                ];
                
                if let view = geometryEditViewController?.view {
                    for subview in view.subviews {
                        subview.removeFromSuperview();
                    }
                }
                navController.popToRootViewController(animated: false);

                geometryEditViewController?.dismiss(animated: false);
                geometryEditViewController = nil;

//                Nimble_Snapshots.setNimbleTolerance(0.1);
//                Nimble_Snapshots.recordAllSnapshots();
            }
            
            afterEach {
                if let view = geometryEditViewController?.view {
                    for subview in view.subviews {
                        subview.removeFromSuperview();
                    }
                }
                navController.popToRootViewController(animated: false);

                geometryEditViewController?.dismiss(animated: false);
                geometryEditViewController = nil;
                
                window.rootViewController = nil;
            }
            
            it("geometry edit coordinator launch") {
//                let expectation: XCTestExpectation = self.expectation(description: "Wait for map rendering")
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMKMapViewDelegate()
                
//                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
//                    expectation.fulfill()
//                }
                
                let mockGeometryEditDelegate = MockGeometryEditDelegate();
                
                let coordinator: GeometryEditCoordinator = GeometryEditCoordinator(fieldDefinition: field, andGeometry: point, andPinImage: UIImage(named: "observations"), andDelegate: mockGeometryEditDelegate, andNavigationController: navController, scheme: MAGEScheme.scheme());
                coordinator.setMapEventDelegte(mockMapDelegate);
                coordinator.start();
                
                expect(mockMapDelegate.finishedRendering).toEventually(beTrue())
                
//                let result: XCTWaiter.Result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
//                XCTAssertEqual(result, .completed)
                
//                expect(window.rootViewController?.view).to(haveValidSnapshot(usesDrawRect: true));
            }
            
            it("latitude longitude tab") {
//                let expectation: XCTestExpectation = self.expectation(description: "Wait for map rendering")
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMKMapViewDelegate()
                
//                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
//                    expectation.fulfill()
//                }
                
                let mockGeometryEditCoordinator = MockGeometryEditCoordinator();
                mockGeometryEditCoordinator._fieldName = field[FieldKey.name.key] as? String;
                mockGeometryEditCoordinator.currentGeometry = point;
                geometryEditViewController = GeometryEditViewController(coordinator: mockGeometryEditCoordinator, scheme: MAGEScheme.scheme());
                
                geometryEditViewController?.mapDelegate?.setMapEventDelegte(mockMapDelegate)
                
                navController.pushViewController(geometryEditViewController!, animated: false);

                expect(mockMapDelegate.finishedRendering).toEventually(beTrue())

//                let result: XCTWaiter.Result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
//                XCTAssertEqual(result, .completed)
                
//                expect(window.rootViewController?.view).to(haveValidSnapshot());
            }
            
            it("switch to mgrs tab") {
//                let expectation: XCTestExpectation = self.expectation(description: "Wait for map rendering")
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMKMapViewDelegate()
                
//                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
//                    expectation.fulfill()
//                }
                
                let mockGeometryEditCoordinator = MockGeometryEditCoordinator();
                mockGeometryEditCoordinator._fieldName = field[FieldKey.name.key] as? String;
                mockGeometryEditCoordinator.currentGeometry = point;
                geometryEditViewController = GeometryEditViewController(coordinator: mockGeometryEditCoordinator, scheme: MAGEScheme.scheme());
                
                geometryEditViewController?.mapDelegate?.setMapEventDelegte(mockMapDelegate)
                
                navController.pushViewController(geometryEditViewController!, animated: false);

//                let result: XCTWaiter.Result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
//                XCTAssertEqual(result, .completed)
                
//                expect(mockMapDelegate.finishedRendering).toEventually(beTrue())
                
                tester().tapView(withAccessibilityLabel: "MGRS");
                tester().waitForTappableView(withAccessibilityLabel: "MGRS Value")
//                expect(window.rootViewController?.view).to(haveValidSnapshot());
            }
            
            it("clear a geometry") {
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockGeometryEditDelegate = MockGeometryEditDelegate();
                
                let coordinator: GeometryEditCoordinator = GeometryEditCoordinator(fieldDefinition: field, andGeometry: point, andPinImage: UIImage(named: "observations"), andDelegate: mockGeometryEditDelegate, andNavigationController: navController, scheme: MAGEScheme.scheme());
                coordinator.start();
                
                tester().waitForTappableView(withAccessibilityLabel: "more_menu");
                tester().waitForView(withAccessibilityLabel: "Latitude Value");
                let latTextField = viewTester().usingLabel("Latitude Value").view as? UITextField;
                expect(latTextField?.text).toNot(beNil());
                let lonTextField = viewTester().usingLabel("Longitude Value").view as? UITextField;
                expect(lonTextField?.text).toNot(beNil());
                tester().tapView(withAccessibilityLabel: "more_menu", traits: .button);
                tester().wait(forTimeInterval: 0.2);
                tester().waitForTappableView(withAccessibilityLabel: "clear");
                tester().tapView(withAccessibilityLabel: "clear");
                expect(lonTextField?.text).toNot(beNil());
                expect(latTextField?.text).toNot(beNil());
                tester().tapView(withAccessibilityLabel: "Apply");
                expect(mockGeometryEditDelegate.geometryEditCompleteCalled).to(beTrue());
                let geometry: SFGeometry? = mockGeometryEditDelegate.geometryEditCompleteGeometry;
                expect(geometry).to(beNil());
            }
            
            it("create a point with long press") {
                let mockGeometryEditDelegate = MockGeometryEditDelegate();
                
                let coordinator: GeometryEditCoordinator = GeometryEditCoordinator(fieldDefinition: field, andGeometry: nil, andPinImage: UIImage(named: "observations"), andDelegate: mockGeometryEditDelegate, andNavigationController: navController, scheme: MAGEScheme.scheme());
                coordinator.start();
                
                tester().waitForView(withAccessibilityLabel: "point");
                tester().tapView(withAccessibilityLabel: "point");
                TestHelpers.printAllAccessibilityLabelsInWindows();
                viewTester().usingLabel("Geometry Edit Map").longPress(withDuration: 0.5);
                TestHelpers.printAllAccessibilityLabelsInWindows();
                let latTextField = viewTester().usingLabel("Latitude Value").view as? UITextField;
                expect(latTextField?.text).toNot(beNil());
                let lonTextField = viewTester().usingLabel("Longitude Value").view as? UITextField;
                expect(lonTextField?.text).toNot(beNil());
                TestHelpers.printAllAccessibilityLabelsInWindows();
                tester().waitForView(withAccessibilityLabel: "shape_edit");
//                expect(window.rootViewController?.view).to(haveValidSnapshot());
                
                tester().tapView(withAccessibilityLabel: "Apply");
                expect(mockGeometryEditDelegate.geometryEditCompleteCalled).to(beTrue());
                let geometry: SFGeometry? = mockGeometryEditDelegate.geometryEditCompleteGeometry;
                expect(geometry).toNot(beNil());
                expect(geometry?.geometryType).to(equal(SF_POINT))
            }
            
            xit("create a line with long press") {
                let mockGeometryEditDelegate = MockGeometryEditDelegate();
                
                let coordinator: GeometryEditCoordinator = GeometryEditCoordinator(fieldDefinition: field, andGeometry: nil, andPinImage: UIImage(named: "observations"), andDelegate: mockGeometryEditDelegate, andNavigationController: navController, scheme: MAGEScheme.scheme());
                coordinator.start();
                
                tester().waitForTappableView(withAccessibilityLabel: "Apply");
                tester().waitForView(withAccessibilityLabel: "line");
                tester().tapView(withAccessibilityLabel: "line");
                viewTester().usingLabel("Geometry Edit Map").longPress();
                let latTextField = viewTester().usingLabel("Latitude Value").view as? UITextField;
                let initialLat = latTextField?.text;
                expect(initialLat).toNot(beNil());
                let lonTextField = viewTester().usingLabel("Longitude Value").view as? UITextField;
                let initialLon = lonTextField?.text;
                expect(initialLon).toNot(beNil());
                tester().waitForView(withAccessibilityLabel: "shape_edit");
                
                let centerOfMap = viewTester().usingLabel("Geometry Edit Map").view.center;
//                viewTester().usingLabel("Geometry Edit Map").view.drag(from: centerOfMap, to: CGPoint(x: centerOfMap.x + 40, y: centerOfMap.y + 40));
                viewTester().waitForAnimationsToFinish();
                viewTester().usingLabel("Geometry Edit Map").view.longPress(at: CGPoint(x: centerOfMap.x + 40, y: centerOfMap.y + 40), duration: 0.5);
                tester().waitForAnimationsToFinish();
                tester().waitForView(withAccessibilityLabel: "shape_edit");
                TestHelpers.printAllAccessibilityLabelsInWindows()
                tester().waitForView(withAccessibilityLabel: "shape_point");
                
                expect(latTextField?.text).toNot(equal(initialLat));
                expect(lonTextField?.text).toNot(equal(initialLon));
                
                tester().tapView(withAccessibilityLabel: "Apply");
                expect(mockGeometryEditDelegate.geometryEditCompleteCalled).to(beTrue());
                let geometry: SFGeometry? = mockGeometryEditDelegate.geometryEditCompleteGeometry;
                expect(geometry).toNot(beNil());
                expect(geometry?.geometryType).to(equal(SF_LINESTRING))
            }
            
            // this test will not run in conjunction with other tests, the map will not drag
            xit("create a rectangle with long press") {
                let mockGeometryEditDelegate = MockGeometryEditDelegate();
                
                let coordinator: GeometryEditCoordinator = GeometryEditCoordinator(fieldDefinition: field, andGeometry: nil, andPinImage: UIImage(named: "observations"), andDelegate: mockGeometryEditDelegate, andNavigationController: navController, scheme: MAGEScheme.scheme());
                coordinator.start();
                
                tester().waitForView(withAccessibilityLabel: "rectangle");
                tester().tapView(withAccessibilityLabel: "rectangle");
                viewTester().usingLabel("Geometry Edit Map").longPress();
                let latTextField = viewTester().usingLabel("Latitude Value").view as? UITextField;
                let initialLat = latTextField?.text;
                expect(initialLat).toNot(beNil());
                let lonTextField = viewTester().usingLabel("Longitude Value").view as? UITextField;
                let initialLon = lonTextField?.text;
                expect(initialLon).toNot(beNil());
                tester().waitForView(withAccessibilityLabel: "shape_edit");
                
                let centerOfMap = viewTester().usingLabel("Geometry Edit Map").view.center;
                viewTester().usingLabel("Geometry Edit Map").view.drag(from: centerOfMap, to: CGPoint(x: centerOfMap.x + 200, y: centerOfMap.y + 200));
                tester().wait(forTimeInterval: 0.3);
                viewTester().usingLabel("Geometry Edit Map").longPress();
                tester().waitForView(withAccessibilityLabel: "shape_edit");
                
                tester().tapView(withAccessibilityLabel: "Apply");
                tester().wait(forTimeInterval: 0.5);
                expect(mockGeometryEditDelegate.geometryEditCompleteCalled).to(beTrue());
                let geometry: SFGeometry? = mockGeometryEditDelegate.geometryEditCompleteGeometry;
                expect(geometry).toNot(beNil());
                expect(geometry?.geometryType).to(equal(SF_POLYGON))
                let poly = geometry as? SFPolygon;
                let linestrings: [SFLineString] = poly?.lineStrings() as? [SFLineString] ?? [];
                expect(linestrings.count).to(equal(1));
                expect(linestrings[0].numPoints()).to(equal(5))
            }
            
            // cannot get the long presses to work properly in a test
            xit("create a polygon with long press") {
                let mockGeometryEditDelegate = MockGeometryEditDelegate();
                
                let coordinator: GeometryEditCoordinator = GeometryEditCoordinator(fieldDefinition: field, andGeometry: nil, andPinImage: UIImage(named: "observations"), andDelegate: mockGeometryEditDelegate, andNavigationController: navController, scheme: MAGEScheme.scheme());
                coordinator.start();
                
                tester().waitForView(withAccessibilityLabel: "polygon");
                tester().tapView(withAccessibilityLabel: "polygon");
                viewTester().usingLabel("Geometry Edit Map").longPress();
                let latTextField = viewTester().usingLabel("Latitude Value").view as? UITextField;
                let initialLat = latTextField?.text;
                expect(initialLat).toNot(beNil());
                let lonTextField = viewTester().usingLabel("Longitude Value").view as? UITextField;
                let initialLon = lonTextField?.text;
                expect(initialLon).toNot(beNil());
                tester().waitForView(withAccessibilityLabel: "shape_edit");
                
                let centerOfMap = viewTester().usingLabel("Geometry Edit Map").view.center;
                viewTester().usingLabel("Geometry Edit Map").view.drag(from: centerOfMap, to: CGPoint(x: centerOfMap.x + 200, y: centerOfMap.y + 200));
                tester().waitForAnimationsToFinish();
                viewTester().usingLabel("Geometry Edit Map").longPress();
                tester().waitForView(withAccessibilityLabel: "shape_edit");
                viewTester().usingLabel("Geometry Edit Map").view.drag(from: CGPoint(x: centerOfMap.x + 200, y: centerOfMap.y + 200), to: CGPoint(x: centerOfMap.x + 200, y: centerOfMap.y - 200));
                tester().waitForAnimationsToFinish();
                viewTester().usingLabel("Geometry Edit Map").longPress();
                tester().waitForView(withAccessibilityLabel: "shape_edit");
                
                expect(latTextField?.text).toNot(equal(initialLat));
                expect(lonTextField?.text).toNot(equal(initialLon));
                
                tester().tapView(withAccessibilityLabel: "Apply");
                expect(mockGeometryEditDelegate.geometryEditCompleteCalled).to(beTrue());
                let geometry: SFGeometry? = mockGeometryEditDelegate.geometryEditCompleteGeometry;
                expect(geometry).toNot(beNil());
                expect(geometry?.geometryType).to(equal(SF_POLYGON))
                let poly = geometry as? SFPolygon;
                let linestrings: [SFLineString] = poly?.lineStrings() as? [SFLineString] ?? [];
                expect(linestrings.count).to(equal(1));
                expect(linestrings[0].numPoints()).to(equal(4))
            }
        }
    }
}

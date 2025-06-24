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

@testable import MAGE

class GeometryEditViewControllerTests: AsyncMageCoreDataTestCase {
    
    var geometryEditViewController: GeometryEditViewController?
    let navController = UINavigationController();
    
    var window: UIWindow!;
    var field: [String: Any]!
    
    @MainActor
    override func setUp() async throws {
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
    }
    
    @MainActor
    override func tearDown() async throws {
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
   
    @MainActor
    func testGeometryEditCoordinatorLaunch() async {
        let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
        let mockMapDelegate = MockMKMapViewDelegate()
        let mockGeometryEditDelegate = MockGeometryEditDelegate();
        
        let coordinator: GeometryEditCoordinator = GeometryEditCoordinator(fieldDefinition: field, andGeometry: point, andPinImage: UIImage(named: "observations"), andDelegate: mockGeometryEditDelegate, andNavigationController: navController, scheme: MAGEScheme.scheme());
        coordinator.setMapEventDelegte(mockMapDelegate);
        coordinator.start();
        
        let predicate = NSPredicate { _, _ in
            return mockMapDelegate.finishedRendering == true
        }
        let delegateExpectation = XCTNSPredicateExpectation(predicate: predicate, object: .none)
        await fulfillment(of: [delegateExpectation], timeout: 2) // FLAKEY TEST, 2 seconds not always long enough...
    }
    
    @MainActor
    func testLattiudeLogitudeTab() async {
        let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
        let mockMapDelegate = MockMKMapViewDelegate()
        let mockGeometryEditCoordinator = MockGeometryEditCoordinator();
        mockGeometryEditCoordinator._fieldName = field[FieldKey.name.key] as? String;
        mockGeometryEditCoordinator.currentGeometry = point;
        geometryEditViewController = GeometryEditViewController(coordinator: mockGeometryEditCoordinator, scheme: MAGEScheme.scheme());
        
        geometryEditViewController?.mapDelegate?.setMapEventDelegte(mockMapDelegate)
        
        navController.pushViewController(geometryEditViewController!, animated: false);
        
        let predicate = NSPredicate { _, _ in
            return mockMapDelegate.finishedRendering == true
        }
        let delegateExpectation = XCTNSPredicateExpectation(predicate: predicate, object: .none)
        await fulfillment(of: [delegateExpectation], timeout: 2)
    }
    
    @MainActor
    func testSwitchToMGRSTab() {
        let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
        let mockMapDelegate = MockMKMapViewDelegate()
        let mockGeometryEditCoordinator = MockGeometryEditCoordinator();
        mockGeometryEditCoordinator._fieldName = field[FieldKey.name.key] as? String;
        mockGeometryEditCoordinator.currentGeometry = point;
        geometryEditViewController = GeometryEditViewController(coordinator: mockGeometryEditCoordinator, scheme: MAGEScheme.scheme());
        geometryEditViewController?.mapDelegate?.setMapEventDelegte(mockMapDelegate)
        
        navController.pushViewController(geometryEditViewController!, animated: false);
        
        tester().tapView(withAccessibilityLabel: "MGRS");
        tester().waitForTappableView(withAccessibilityLabel: "MGRS Value")
    }
    
    @MainActor
    func testCreateAPointWithLongPress() {
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
        tester().tapView(withAccessibilityLabel: "Apply");
        expect(mockGeometryEditDelegate.geometryEditCompleteCalled).to(beTrue());
        let geometry: SFGeometry? = mockGeometryEditDelegate.geometryEditCompleteGeometry;
        expect(geometry).toNot(beNil());
        expect(geometry?.geometryType).to(equal(.POINT))
    }
}

//
//  GeometryViewTests.swift
//  MAGE
//
//  Created by Daniel Barela on 5/12/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import sf_ios
//import Nimble_Snapshots

@testable import MAGE

class GeometryViewTests: AsyncMageCoreDataTestCase {
    
    var field: [String: Any]!
    
    var geometryFieldView: GeometryView?
    var view: UIView!
    var controller: UIViewController!
    var window: UIWindow!;
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        controller = UIViewController();
        view = UIView(forAutoLayout: ());
        view.autoSetDimension(.width, toSize: UIScreen.main.bounds.width);
        view.backgroundColor = .systemBackground;
        
        controller?.view.addSubview(view);
        
        window = TestHelpers.getKeyWindowVisible();
        window.rootViewController = controller;
        
        geometryFieldView?.removeFromSuperview();
        geometryFieldView = nil;
        for subview in view.subviews {
            subview.removeFromSuperview();
        }
        
        field = [
            "title": "Field Title",
            "name": "field8",
            "type": "geometry",
            "id": 8
        ];
        
        UserDefaults.standard.mapType = 0;
        UserDefaults.standard.locationDisplay = .latlng;
    }
    
    @MainActor
    override func tearDown() async throws {
        try await super.tearDown()
        geometryFieldView?.removeFromSuperview();
        geometryFieldView = nil;
        for subview in view.subviews {
            subview.removeFromSuperview();
        }
    }
    
    @MainActor
    func testEditModeReferenceImage() {
        let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
        //                let mockMapDelegate = MockMapViewDelegate()
        
        //                let plainDelegate: PlainMapViewDelegate = PlainMapViewDelegate();
        //                plainDelegate.mockMapViewDelegate = mockMapDelegate;
        
        geometryFieldView = GeometryView(field: field, value: point, accuracy: 100.487235, provider: "gps", mapEventDelegate: nil);//, mkmapDelegate: plainDelegate);
        geometryFieldView!.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(geometryFieldView!)
        geometryFieldView?.autoPinEdgesToSuperviewEdges();
        
        expect(self.geometryFieldView?.textField.text) == "40.0085, -105.2678 GPS ± 100.49m"
        expect(self.geometryFieldView?.textField.label.text) == "Field Title"
        
    }
    
    @MainActor
    func testNoInitialValue() {
        //                let mockMapDelegate: MockMapViewDelegate = MockMapViewDelegate()
        
        geometryFieldView = GeometryView(field: field, mapEventDelegate: nil);
        geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(geometryFieldView!)
        geometryFieldView?.autoPinEdgesToSuperviewEdges();
        
        expect(self.geometryFieldView?.mapView.isHidden).to(beTrue());
        expect(self.geometryFieldView?.textField.text) == "";
        expect(self.geometryFieldView?.textField.label.text) == "Field Title"
    }
    
    @MainActor
    func testNonEditModeReferenceImage() {
        let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
        geometryFieldView = GeometryView(field: field, editMode: false, value: point, accuracy: 100.487235, provider: "gps");
        geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(geometryFieldView!)
        geometryFieldView?.autoPinEdgesToSuperviewEdges();
        
        expect(self.geometryFieldView?.latitudeLongitudeButton.currentTitle) == "40.0085, -105.2678";
        expect(self.geometryFieldView?.latitudeLongitudeButton.isEnabled).to(beTrue());
        expect(self.geometryFieldView?.accuracyLabel.text) == "GPS ± 100.49m";
        expect(self.geometryFieldView?.fieldNameLabel.text) == "Field Title"
        expect(self.geometryFieldView?.fieldNameLabel.superview).toNot(beNil());
        
        expect(self.geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
        expect(self.geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
    }
    
    @MainActor
    func testNonEditModeInitialValueSetAsAPoint() {
        let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
        geometryFieldView = GeometryView(field: field, editMode: false, value: point, accuracy: 100.487235, provider: "gps");
        geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(geometryFieldView!)
        geometryFieldView?.autoPinEdgesToSuperviewEdges();
        
        expect(self.geometryFieldView?.latitudeLongitudeButton.currentTitle) == "40.0085, -105.2678";
        expect(self.geometryFieldView?.latitudeLongitudeButton.isEnabled).to(beTrue());
        expect(self.geometryFieldView?.accuracyLabel.text) == "GPS ± 100.49m";
        expect(self.geometryFieldView?.fieldNameLabel.text) == "Field Title"
        expect(self.geometryFieldView?.fieldNameLabel.superview).toNot(beNil())
        
        expect(self.geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
        expect(self.geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
    }
    
    @MainActor
    func testInitialValueSetAsAPoint() {
        let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
        geometryFieldView = GeometryView(field: field, value: point, accuracy: 100.487235, provider: "gps");
        geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(geometryFieldView!)
        geometryFieldView?.autoPinEdgesToSuperviewEdges();
        
        expect(self.geometryFieldView?.mapView.isHidden).to(beFalse());
        expect(self.geometryFieldView?.textField.text) == "40.0085, -105.2678 GPS ± 100.49m";
        expect(self.geometryFieldView?.textField.label.text) == "Field Title"
        
        expect(self.geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
        expect(self.geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
    }
    
    @MainActor
    func testInitialValueSetAsAPointNoTitle() {
        field[FieldKey.title.key] = nil;
        
        let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
        geometryFieldView = GeometryView(field: field, value: point, accuracy: 100.487235, provider: "gps");
        geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(geometryFieldView!)
        geometryFieldView?.autoPinEdgesToSuperviewEdges();
        
        expect(self.geometryFieldView?.mapView.isHidden).to(beFalse());
        expect(self.geometryFieldView?.textField.text) == "40.0085, -105.2678 GPS ± 100.49m";
        expect(self.geometryFieldView?.textField.label.text) == ""
        
        expect(self.geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
        expect(self.geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
    }
    
    @MainActor
    func testInitialValueSetAsAPointMGRS() {
        UserDefaults.standard.locationDisplay = .mgrs
        
        let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
        
        geometryFieldView = GeometryView(field: field, value: point, accuracy: 100.487235, provider: "gps");
        geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(geometryFieldView!)
        geometryFieldView?.autoPinEdgesToSuperviewEdges();
        
        expect(self.geometryFieldView?.mapView.isHidden).to(beFalse());
        expect(self.geometryFieldView?.textField.text) == "13TDE7714328734 GPS ± 100.49m";
        expect(self.geometryFieldView?.textField.label.text) == "Field Title"
        
        expect(self.geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
        expect(self.geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
    }
    
    @MainActor
    func testInitalValueSetWithObservationWithoutGeometry() {
        let observation: Observation = ObservationBuilder.createBlankObservation()
        
        geometryFieldView = GeometryView(field: field, observation: observation);
        geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(geometryFieldView!)
        geometryFieldView?.autoPinEdgesToSuperviewEdges();
        
        expect(self.geometryFieldView?.mapView.isHidden).to(beTrue());
        expect(self.geometryFieldView?.textField.text) == "";
        expect(self.geometryFieldView?.textField.label.text) == "Field Title"
    }
    
    @MainActor
    func testInitialValueSetWithObservation() {
        let observation: Observation = ObservationBuilder.createPointObservation();
        
        geometryFieldView = GeometryView(field: field, observation: observation);
        geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(geometryFieldView!)
        geometryFieldView?.autoPinEdgesToSuperviewEdges();
        
        expect(self.geometryFieldView?.mapView.isHidden).to(beFalse());
        expect(self.geometryFieldView?.textField.text) == "40.0085, -105.2678 ";
        expect(self.geometryFieldView?.textField.label.text) == "Field Title"
        
        let point: SFPoint = observation.geometry!.centroid();
        expect(self.geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
        expect(self.geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
        TestHelpers.printAllAccessibilityLabelsInWindows()
        //                tester().waitForView(withAccessibilityLabel: "Observation Annotation \(observation.objectID.uriRepresentation())");
    }
    
    @MainActor
    func testInitialValueSetWithObservationWithAccuracy() {
        let observation: Observation = ObservationBuilder.createPointObservation();
        ObservationBuilder.addObservationProperty(observation: observation, key: "provider", value: "gps")
        ObservationBuilder.addObservationProperty(observation: observation, key: "accuracy", value: 100.487235)
        
        geometryFieldView = GeometryView(field: field, observation: observation);
        geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(geometryFieldView!)
        geometryFieldView?.autoPinEdgesToSuperviewEdges();
        
        expect(self.geometryFieldView?.mapView.isHidden).to(beFalse());
        expect(self.geometryFieldView?.textField.text) == "40.0085, -105.2678 GPS ± 100.49m";
        expect(self.geometryFieldView?.textField.label.text) == "Field Title"
        
        let point: SFPoint = observation.geometry!.centroid();
        expect(self.geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
        expect(self.geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
        //                tester().waitForView(withAccessibilityLabel: "Observation Annotation \(observation.objectID.uriRepresentation())");
    }
    
    @MainActor
    func testInitialValueSetWithObservationWithAccuracyAndProvider() {
        let observation: Observation = ObservationBuilder.createPointObservation();
        ObservationBuilder.addObservationProperty(observation: observation, key: "accuracy", value: 100.487235)
        ObservationBuilder.addObservationProperty(observation: observation, key: "provider", value: "gps")
        
        geometryFieldView = GeometryView(field: field, observation: observation);
        geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(geometryFieldView!)
        geometryFieldView?.autoPinEdgesToSuperviewEdges();
        
        expect(self.geometryFieldView?.mapView.isHidden).to(beFalse());
        expect(self.geometryFieldView?.textField.text) == "40.0085, -105.2678 GPS ± 100.49m";
        expect(self.geometryFieldView?.textField.label.text) == "Field Title"
        
        let point: SFPoint = observation.geometry!.centroid();
        expect(self.geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
        expect(self.geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
        //                tester().waitForView(withAccessibilityLabel: "Observation Annotation \(observation.objectID.uriRepresentation())");
    }
    
    @MainActor
    func testInitialValueSetWithObsrvationLine() {
        let observation: Observation = ObservationBuilder.createLineObservation();
        
        geometryFieldView = GeometryView(field: field, observation: observation);
        geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(geometryFieldView!)
        geometryFieldView?.autoPinEdgesToSuperviewEdges();
        
        tester().waitForAnimationsToFinish();
        
        let point: SFPoint = observation.geometry!.centroid();
        expect(self.geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
        expect(self.geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
        expect(self.geometryFieldView?.mapView.isHidden).to(beFalse());
        expect(self.geometryFieldView?.textField.text) == "40.0085, -105.2666 ";
        expect(self.geometryFieldView?.textField.label.text) == "Field Title"
    }
    
    @MainActor
    func testInitialValueSetWithObsrvationPolygon() {
        let observation: Observation = ObservationBuilder.createPolygonObservation();
        geometryFieldView = GeometryView(field: field, observation: observation);
        geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(geometryFieldView!)
        geometryFieldView?.autoPinEdgesToSuperviewEdges();
        
        expect(self.geometryFieldView?.mapView.isHidden).to(beFalse());
        expect(self.geometryFieldView?.textField.text) == "40.0093, -105.2666 ";
        expect(self.geometryFieldView?.textField.label.text) == "Field Title"
        
        let point: SFPoint = observation.geometry!.centroid();
        expect(self.geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
        expect(self.geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
    }
    
    @MainActor
    func testSetValueLaterWithObservationWithAccuracyAndProvider() {
        let observation: Observation = ObservationBuilder.createPointObservation();
        ObservationBuilder.addObservationProperty(observation: observation, key: "accuracy", value: 100.487235)
        ObservationBuilder.addObservationProperty(observation: observation, key: "provider", value: "gps")
        
        geometryFieldView = GeometryView(field: field, observation: nil);
        geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(geometryFieldView!)
        geometryFieldView?.autoPinEdgesToSuperviewEdges();
        
        geometryFieldView?.setObservation(observation: observation);
        
        expect(self.geometryFieldView?.mapView.isHidden).to(beFalse());
        expect(self.geometryFieldView?.textField.text) == "40.0085, -105.2678 GPS ± 100.49m";
        expect(self.geometryFieldView?.textField.label.text) == "Field Title"
        
        let point: SFPoint = observation.geometry!.centroid();
        expect(self.geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
        expect(self.geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
        //                tester().waitForView(withAccessibilityLabel: "Observation Annotation \(observation.objectID.uriRepresentation())");
    }
    
    @MainActor
    func testSetValueLater() {
        let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
        
        geometryFieldView = GeometryView(field: field);
        geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(geometryFieldView!)
        geometryFieldView?.autoPinEdgesToSuperviewEdges();
        
        geometryFieldView?.setValue(point);
        
        expect(self.geometryFieldView?.mapView.isHidden).to(beFalse());
        expect(self.geometryFieldView?.textField.text) == "40.0085, -105.2678 ";
        expect(self.geometryFieldView?.textField.label.text) == "Field Title"
        
        expect(self.geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
        expect(self.geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
    }
    
    @MainActor
    func testSetValueLaterWithAccuracy() {
        let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
        geometryFieldView = GeometryView(field: field);
        geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
        geometryFieldView?.setValue(point, accuracy: 100.487235, provider: "gps");
        
        view.addSubview(geometryFieldView!)
        geometryFieldView?.autoPinEdgesToSuperviewEdges();
        
        expect(self.geometryFieldView?.mapView.isHidden).to(beFalse());
        expect(self.geometryFieldView?.textField.text) == "40.0085, -105.2678 GPS ± 100.49m";
        expect(self.geometryFieldView?.textField.label.text) == "Field Title"
        
        expect(self.geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
        expect(self.geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
    }
    
    @MainActor
    func testSetValueLaterWithAccuracyAndNoProvider() {
        let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
        
        geometryFieldView = GeometryView(field: field);
        geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
        geometryFieldView?.setValue(point, accuracy: 100.487235);
        
        view.addSubview(geometryFieldView!)
        geometryFieldView?.autoPinEdgesToSuperviewEdges();
        
        expect(self.geometryFieldView?.mapView.isHidden).to(beFalse());
        expect(self.geometryFieldView?.textField.text) == "40.0085, -105.2678 ";
        expect(self.geometryFieldView?.textField.label.text) == "Field Title"
        
        expect(self.geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
        expect(self.geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
    }
    
    @MainActor
    func testSetValidFalse() {
        geometryFieldView = GeometryView(field: field);
        geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(geometryFieldView!)
        geometryFieldView?.autoPinEdgesToSuperviewEdges();
        geometryFieldView?.setValid(false);
        
        //                expect(view).to(haveValidSnapshot());
        
        expect(self.geometryFieldView?.mapView.isHidden).to(beTrue());
        expect(self.geometryFieldView?.textField.text) == "";
        expect(self.geometryFieldView?.textField.label.text) == "Field Title"
    }
    
    @MainActor
    func testSetValidAfterBeingInvalid() {
        
        geometryFieldView = GeometryView(field: field);
        geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(geometryFieldView!)
        geometryFieldView?.autoPinEdgesToSuperviewEdges();
        geometryFieldView?.setValid(false)
        geometryFieldView?.setValid(true);
        
        expect(self.geometryFieldView?.mapView.isHidden).to(beTrue());
        expect(self.geometryFieldView?.textField.text) == "";
        expect(self.geometryFieldView?.textField.label.text) == "Field Title"
        expect(self.geometryFieldView?.textField.textColor) != MAGEScheme.scheme().colorScheme.errorColor;
    }
    
    @MainActor
    func testRequiredFieldIsInvalidIfEmpty() {
        field[FieldKey.required.key] = true;
        
        geometryFieldView = GeometryView(field: field);
        geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
        
        expect(self.geometryFieldView?.isEmpty()) == true;
        expect(self.geometryFieldView?.isValid(enforceRequired: true)) == false;
        
        expect(self.geometryFieldView?.mapView.isHidden).to(beTrue());
        expect(self.geometryFieldView?.textField.text) == "";
        expect(self.geometryFieldView?.textField.label.text) == "Field Title *"
    }
    
    @MainActor
    func testRequiredFieldIsValidIfNotEmpty() {
        let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
        field[FieldKey.required.key] = true;
        
        geometryFieldView = GeometryView(field: field, value: point);
        geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
        
        expect(self.geometryFieldView?.isEmpty()) == false;
        expect(self.geometryFieldView?.isValid(enforceRequired: true)) == true;
        
        expect(self.geometryFieldView?.mapView.isHidden).to(beFalse());
        expect(self.geometryFieldView?.textField.text) == "40.0085, -105.2678 ";
        expect(self.geometryFieldView?.textField.label.text) == "Field Title *"
    }
    
    @MainActor
    func testSetValueViaInput() {
        let delegate = MockFieldDelegate();
        
        let nc = UINavigationController();
        
        window.rootViewController = nc;
        controller.removeFromParent();
        nc.pushViewController(controller, animated: false);
        
        geometryFieldView = GeometryView(field: field, delegate: delegate);
        geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(geometryFieldView!)
        geometryFieldView?.autoPinEdgesToSuperviewEdges();
        
        tester().waitForView(withAccessibilityLabel: field[FieldKey.name.key] as? String);
        geometryFieldView?.handleTap();
        expect(delegate.launchFieldSelectionViewControllerCalled).to(beTrue());
        expect(delegate.viewControllerToLaunch).to(beAnInstanceOf(GeometryEditViewController.self));
        
        nc.pushViewController(delegate.viewControllerToLaunch!, animated: false);
        
        tester().waitForView(withAccessibilityLabel: "Latitude Value")
        tester().clearText(fromAndThenEnterText: "1.00000", intoViewWithAccessibilityLabel: "Latitude Value")
        tester().clearText(fromAndThenEnterText: "1.00000", intoViewWithAccessibilityLabel: "Longitude Value")
        viewTester().usingFirstResponder().view.resignFirstResponder();
        tester().tapView(withAccessibilityLabel: "Apply");
        
        tester().waitForView(withAccessibilityLabel: field[FieldKey.name.key] as? String);
        expect((self.viewTester().usingLabel("\(self.field[FieldKey.name.key] as? String ?? "") value")!.view as! MDCFilledTextField).text) == "1.0000, 1.0000 "
        
        expect(UIApplication.getTopViewController()).toNot(beAnInstanceOf(delegate.viewControllerToLaunch!.classForCoder));
        
        nc.popToRootViewController(animated: false);
        window.rootViewController = controller;
    }
    
    @MainActor
    func testCopyLocation() {
        let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
  
        let mockActionsDelegate: MockObservationActionsDelegate = MockObservationActionsDelegate();
        
        geometryFieldView = GeometryView(field: field, editMode: false, value: point, accuracy: 100.487235, provider: "gps", observationActionsDelegate: mockActionsDelegate);
        geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
        
        view.addSubview(geometryFieldView!)
        geometryFieldView?.autoPinEdgesToSuperviewEdges();
        
        expect(self.geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
        expect(self.geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
        expect(self.geometryFieldView?.latitudeLongitudeButton.currentTitle) == "40.0085, -105.2678";
        expect(self.geometryFieldView?.latitudeLongitudeButton.isEnabled).to(beTrue());
        expect(self.geometryFieldView?.accuracyLabel.text) == "GPS ± 100.49m";
        expect(self.geometryFieldView?.fieldNameLabel.text) == "Field Title"
        
        tester().tapView(withAccessibilityLabel: "location button");
        tester().waitForView(withAccessibilityLabel: "Location 40.0085, -105.2678 copied to clipboard")
    }
}

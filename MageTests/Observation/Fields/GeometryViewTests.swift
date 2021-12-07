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
//import Nimble_Snapshots

@testable import MAGE

class GeometryViewTests: KIFSpec {
    
    override func spec() {
        
        describe("GeometryView") {
            var stackSetup = false;
            var field: [String: Any]!
                        
            var geometryFieldView: GeometryView?
            var view: UIView!
            var controller: UIViewController!
            var window: UIWindow!;
            
            beforeEach {
                if (!stackSetup) {
                    TestHelpers.clearAndSetUpStack();
                    
                    controller = UIViewController();
                    view = UIView(forAutoLayout: ());
                    view.autoSetDimension(.width, toSize: UIScreen.main.bounds.width);
                    view.backgroundColor = .systemBackground;
                    
                    controller?.view.addSubview(view);
                    stackSetup = true;
                }
                
                window = TestHelpers.getKeyWindowVisible();
                window.rootViewController = controller;
                
                geometryFieldView?.removeFromSuperview();
                geometryFieldView = nil;
                for subview in view.subviews {
                    subview.removeFromSuperview();
                }
                MageCoreDataFixtures.clearAllData();
                
                field = [
                    "title": "Field Title",
                    "name": "field8",
                    "type": "geometry",
                    "id": 8
                ];
                
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.showMGRS = false;
//                Nimble_Snapshots.setNimbleTolerance(0.1);
//                Nimble_Snapshots.recordAllSnapshots();
            }
            
            afterEach {
                geometryFieldView?.removeFromSuperview();
                geometryFieldView = nil;
                for subview in view.subviews {
                    subview.removeFromSuperview();
                }
                MageCoreDataFixtures.clearAllData();
            }
            
            it("edit mode reference image") {
                let expectation: XCTestExpectation = self.expectation(description: "Wait for map rendering")
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()
                
                let plainDelegate: PlainMapViewDelegate = PlainMapViewDelegate();
                plainDelegate.mockMapViewDelegate = mockMapDelegate;
                
                geometryFieldView = GeometryView(field: field, value: point, accuracy: 100.487235, provider: "gps", mapEventDelegate: mockMapDelegate);//, mkmapDelegate: plainDelegate);
                geometryFieldView!.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView!)
                geometryFieldView?.autoPinEdgesToSuperviewEdges();
                
                expect(geometryFieldView?.textField.text) == "40.00850, -105.26780 GPS ± 100.49m"
                expect(geometryFieldView?.textField.label.text) == "Field Title"
                
//                expect(view).to(haveValidSnapshot(usesDrawRect: true));
                
            }
            
            it("no initial value") {
                let mockMapDelegate: MockMapViewDelegate = MockMapViewDelegate()

                geometryFieldView = GeometryView(field: field, mapEventDelegate: mockMapDelegate);
                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());

                view.addSubview(geometryFieldView!)
                geometryFieldView?.autoPinEdgesToSuperviewEdges();
                
                expect(geometryFieldView?.mapView.isHidden).to(beTrue());
                expect(geometryFieldView?.textField.text) == "";
                expect(geometryFieldView?.textField.label.text) == "Field Title"
            }
            
            it("non edit mode reference image") {
                let expectation: XCTestExpectation = self.expectation(description: "Wait for map rendering")

                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    expect(geometryFieldView?.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView?.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    expectation.fulfill()
                }
                                
                geometryFieldView = GeometryView(field: field, editMode: false, value: point, accuracy: 100.487235, provider: "gps", mapEventDelegate: mockMapDelegate);
                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView!)
                geometryFieldView?.autoPinEdgesToSuperviewEdges();
                
                expect(geometryFieldView?.latitudeLongitudeButton.currentTitle) == "40.00850, -105.26780";
                expect(geometryFieldView?.latitudeLongitudeButton.isEnabled).to(beTrue());
                expect(geometryFieldView?.accuracyLabel.text) == "GPS ± 100.49m";
                expect(geometryFieldView?.fieldNameLabel.text) == "Field Title"
                expect(geometryFieldView?.fieldNameLabel.superview).toNot(beNil());
                
                let result: XCTWaiter.Result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
                XCTAssertEqual(result, .completed)
//                expect(view).to(haveValidSnapshot());
            }
            
            it("non edit mode initial value set as a point") {
                let expectation: XCTestExpectation = self.expectation(description: "Wait for map rendering")

                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    expect(geometryFieldView?.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView?.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    expectation.fulfill()
                }
                                
                geometryFieldView = GeometryView(field: field, editMode: false, value: point, accuracy: 100.487235, provider: "gps", mapEventDelegate: mockMapDelegate);
                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView!)
                geometryFieldView?.autoPinEdgesToSuperviewEdges();
                
                let result: XCTWaiter.Result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
                XCTAssertEqual(result, .completed)
                
                expect(geometryFieldView?.latitudeLongitudeButton.currentTitle) == "40.00850, -105.26780";
                expect(geometryFieldView?.latitudeLongitudeButton.isEnabled).to(beTrue());
                expect(geometryFieldView?.accuracyLabel.text) == "GPS ± 100.49m";
                expect(geometryFieldView?.fieldNameLabel.text) == "Field Title"
                expect(geometryFieldView?.fieldNameLabel.superview).toNot(beNil())
            }

            it("initial value set as a point") {
                let expectation: XCTestExpectation = self.expectation(description: "Wait for map rendering")

                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()

                mockMapDelegate.mapDidFinishLoadingClosure = { mapView in
                    expect(geometryFieldView?.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView?.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    expectation.fulfill()
                }
                
                geometryFieldView = GeometryView(field: field, value: point, accuracy: 100.487235, provider: "gps", mapEventDelegate: mockMapDelegate);
                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView!)
                geometryFieldView?.autoPinEdgesToSuperviewEdges();
                                
                let result: XCTWaiter.Result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
                XCTAssertEqual(result, .completed)
                
                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
                expect(geometryFieldView?.textField.text) == "40.00850, -105.26780 GPS ± 100.49m";
                expect(geometryFieldView?.textField.label.text) == "Field Title"
            }
            
            it("initial value set as a point no title") {
                let expectation: XCTestExpectation = self.expectation(description: "Wait for map rendering")
                field[FieldKey.title.key] = nil;
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    expect(geometryFieldView?.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView?.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    expectation.fulfill()
                }
                                
                geometryFieldView = GeometryView(field: field, value: point, accuracy: 100.487235, provider: "gps", mapEventDelegate: mockMapDelegate);
                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView!)
                geometryFieldView?.autoPinEdgesToSuperviewEdges();
                
                let result: XCTWaiter.Result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
                XCTAssertEqual(result, .completed)
                
                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
                expect(geometryFieldView?.textField.text) == "40.00850, -105.26780 GPS ± 100.49m";
                expect(geometryFieldView?.textField.label.text) == ""
            }
            
            it("initial value set as a point MGRS") {
                let expectation: XCTestExpectation = self.expectation(description: "Wait for map rendering")
                UserDefaults.standard.set(true, forKey: "showMGRS");
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishLoadingClosure = { mapView in
                    expect(geometryFieldView?.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView?.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    expectation.fulfill()
                }
                                
                geometryFieldView = GeometryView(field: field, value: point, accuracy: 100.487235, provider: "gps", mapEventDelegate: mockMapDelegate);
                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView!)
                geometryFieldView?.autoPinEdgesToSuperviewEdges();
                
                let result: XCTWaiter.Result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
                XCTAssertEqual(result, .completed)
                
                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
                expect(geometryFieldView?.textField.text) == "13TDE7714328735 GPS ± 100.49m";
                expect(geometryFieldView?.textField.label.text) == "Field Title"
            }
            
            it("initial value set wtih observation without geometry") {
                let observation: Observation = ObservationBuilder.createBlankObservation()
                
                let mockMapDelegate = MockMapViewDelegate()
                
                geometryFieldView = GeometryView(field: field, observation: observation,  mapEventDelegate: mockMapDelegate);
                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView!)
                geometryFieldView?.autoPinEdgesToSuperviewEdges();
                
                expect(geometryFieldView?.mapView.isHidden).to(beTrue());
                expect(geometryFieldView?.textField.text) == "";
                expect(geometryFieldView?.textField.label.text) == "Field Title"
            }
            
            it("initial value set wtih observation") {
                let expectation: XCTestExpectation = self.expectation(description: "Wait for map rendering")
                let observation: Observation = ObservationBuilder.createPointObservation();

                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    let point: SFPoint = observation.geometry!.centroid();
                    expect(geometryFieldView?.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView?.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    tester().waitForView(withAccessibilityLabel: "Observation Annotation \(observation.objectID.uriRepresentation())");
                    expectation.fulfill()
                }
                                
                geometryFieldView = GeometryView(field: field, observation: observation, mapEventDelegate: mockMapDelegate);
                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView!)
                geometryFieldView?.autoPinEdgesToSuperviewEdges();
                
                let result: XCTWaiter.Result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
                XCTAssertEqual(result, .completed)
                
                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
                expect(geometryFieldView?.textField.text) == "40.00850, -105.26780 ";
                expect(geometryFieldView?.textField.label.text) == "Field Title"
            }
            
            it("initial value set wtih observation with accuracy") {
                let expectation: XCTestExpectation = self.expectation(description: "Wait for map rendering")
                let observation: Observation = ObservationBuilder.createPointObservation();
                ObservationBuilder.addObservationProperty(observation: observation, key: "provider", value: "gps")
                ObservationBuilder.addObservationProperty(observation: observation, key: "accuracy", value: 100.487235)
                
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    let point: SFPoint = observation.geometry!.centroid();
                    expect(geometryFieldView?.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView?.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    tester().waitForView(withAccessibilityLabel: "Observation Annotation \(observation.objectID.uriRepresentation())");
                    expectation.fulfill()
                }
                                
                geometryFieldView = GeometryView(field: field, observation: observation, mapEventDelegate: mockMapDelegate);
                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView!)
                geometryFieldView?.autoPinEdgesToSuperviewEdges();
                
                let result: XCTWaiter.Result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
                XCTAssertEqual(result, .completed)
                                
                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
                expect(geometryFieldView?.textField.text) == "40.00850, -105.26780 GPS ± 100.49m";
                expect(geometryFieldView?.textField.label.text) == "Field Title"
            }
            
            it("initial value set wtih observation with accuracy and provider") {
                let expectation: XCTestExpectation = self.expectation(description: "Wait for map rendering")
                let observation: Observation = ObservationBuilder.createPointObservation();
                ObservationBuilder.addObservationProperty(observation: observation, key: "accuracy", value: 100.487235)
                ObservationBuilder.addObservationProperty(observation: observation, key: "provider", value: "gps")
                
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    let point: SFPoint = observation.geometry!.centroid();
                    expect(geometryFieldView?.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView?.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    tester().waitForView(withAccessibilityLabel: "Observation Annotation \(observation.objectID.uriRepresentation())");
                    expectation.fulfill()
                }
                                
                geometryFieldView = GeometryView(field: field, observation: observation, mapEventDelegate: mockMapDelegate);
                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView!)
                geometryFieldView?.autoPinEdgesToSuperviewEdges();
                
                let result: XCTWaiter.Result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
                XCTAssertEqual(result, .completed)
                                
                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
                expect(geometryFieldView?.textField.text) == "40.00850, -105.26780 GPS ± 100.49m";
                expect(geometryFieldView?.textField.label.text) == "Field Title"
            }
            
            it("initial value set wtih observation line") {
                let expectation: XCTestExpectation = self.expectation(description: "Wait for map rendering")

                let observation: Observation = ObservationBuilder.createLineObservation();

                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    expectation.fulfill()
                }
                                
                geometryFieldView = GeometryView(field: field, observation: observation, mapEventDelegate: mockMapDelegate);
                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView!)
                geometryFieldView?.autoPinEdgesToSuperviewEdges();
                
                tester().waitForAnimationsToFinish();
                
                let result: XCTWaiter.Result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
                XCTAssertEqual(result, .completed)
                
                let point: SFPoint = observation.geometry!.centroid();
                expect(geometryFieldView?.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                expect(geometryFieldView?.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
                expect(geometryFieldView?.textField.text) == "40.00850, -105.26655 ";
                expect(geometryFieldView?.textField.label.text) == "Field Title"
            }
            
            it("initial value set wtih observation polygon") {
                let expectation: XCTestExpectation = self.expectation(description: "Wait for map rendering")

                let observation: Observation = ObservationBuilder.createPolygonObservation();

                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    let point: SFPoint = observation.geometry!.centroid();
                    expect(geometryFieldView?.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView?.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    expectation.fulfill()
                }
                
                geometryFieldView = GeometryView(field: field, observation: observation, mapEventDelegate: mockMapDelegate);
                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView!)
                geometryFieldView?.autoPinEdgesToSuperviewEdges();
                
                let result: XCTWaiter.Result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
                XCTAssertEqual(result, .completed)
                                
                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
                expect(geometryFieldView?.textField.text) == "40.00935, -105.26655 ";
                expect(geometryFieldView?.textField.label.text) == "Field Title"
            }
            
            it("set value later wtih observation with accuracy and provider") {
                let expectation: XCTestExpectation = self.expectation(description: "Wait for map rendering")
                let observation: Observation = ObservationBuilder.createPointObservation();
                ObservationBuilder.addObservationProperty(observation: observation, key: "accuracy", value: 100.487235)
                ObservationBuilder.addObservationProperty(observation: observation, key: "provider", value: "gps")
                
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    let point: SFPoint = observation.geometry!.centroid();
                    expect(geometryFieldView?.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView?.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    tester().waitForView(withAccessibilityLabel: "Observation Annotation \(observation.objectID.uriRepresentation())");
                    expectation.fulfill()
                }
                                
                geometryFieldView = GeometryView(field: field, observation: nil, mapEventDelegate: mockMapDelegate);
                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView!)
                geometryFieldView?.autoPinEdgesToSuperviewEdges();
                                
                geometryFieldView?.setObservation(observation: observation);
                
                let result: XCTWaiter.Result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
                XCTAssertEqual(result, .completed)
                
                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
                expect(geometryFieldView?.textField.text) == "40.00850, -105.26780 GPS ± 100.49m";
                expect(geometryFieldView?.textField.label.text) == "Field Title"
            }

            it("set value later") {
                let expectation: XCTestExpectation = self.expectation(description: "Wait for map rendering")

                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()

                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    expect(geometryFieldView?.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView?.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    expectation.fulfill()
                }

                geometryFieldView = GeometryView(field: field, mapEventDelegate: mockMapDelegate);
                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());

                view.addSubview(geometryFieldView!)
                geometryFieldView?.autoPinEdgesToSuperviewEdges();

                geometryFieldView?.setValue(point);
                
                let result: XCTWaiter.Result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
                XCTAssertEqual(result, .completed)
                
                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
                expect(geometryFieldView?.textField.text) == "40.00850, -105.26780 ";
                expect(geometryFieldView?.textField.label.text) == "Field Title"
            }
            
            it("set value later with accuracy") {
                let expectation: XCTestExpectation = self.expectation(description: "Wait for map rendering")
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    expect(geometryFieldView?.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView?.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    expectation.fulfill()
                }
                
                geometryFieldView = GeometryView(field: field, mapEventDelegate: mockMapDelegate);
                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
                geometryFieldView?.setValue(point, accuracy: 100.487235, provider: "gps");
                
                view.addSubview(geometryFieldView!)
                geometryFieldView?.autoPinEdgesToSuperviewEdges();
                
                let result: XCTWaiter.Result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
                XCTAssertEqual(result, .completed)
                
                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
                expect(geometryFieldView?.textField.text) == "40.00850, -105.26780 GPS ± 100.49m";
                expect(geometryFieldView?.textField.label.text) == "Field Title"
            }
            
            it("set value later with accuracy and no provider") {
                let expectation: XCTestExpectation = self.expectation(description: "Wait for map rendering")
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    expect(geometryFieldView?.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView?.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    expectation.fulfill()
                }
                
                geometryFieldView = GeometryView(field: field, mapEventDelegate: mockMapDelegate);
                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
                geometryFieldView?.setValue(point, accuracy: 100.487235);
                
                view.addSubview(geometryFieldView!)
                geometryFieldView?.autoPinEdgesToSuperviewEdges();
                
                let result: XCTWaiter.Result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
                XCTAssertEqual(result, .completed)
                
                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
                expect(geometryFieldView?.textField.text) == "40.00850, -105.26780 ";
                expect(geometryFieldView?.textField.label.text) == "Field Title"
            }

            it("set valid false") {
                let mockMapDelegate = MockMapViewDelegate()
                                
                geometryFieldView = GeometryView(field: field, mapEventDelegate: mockMapDelegate);
                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView!)
                geometryFieldView?.autoPinEdgesToSuperviewEdges();
                geometryFieldView?.setValid(false);
                
//                expect(view).to(haveValidSnapshot());

                expect(geometryFieldView?.mapView.isHidden).to(beTrue());
                expect(geometryFieldView?.textField.text) == "";
                expect(geometryFieldView?.textField.label.text) == "Field Title"
            }

            it("set valid true after being invalid") {
                let mockMapDelegate = MockMapViewDelegate()
                                
                geometryFieldView = GeometryView(field: field, mapEventDelegate: mockMapDelegate);
                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView!)
                geometryFieldView?.autoPinEdgesToSuperviewEdges();
                geometryFieldView?.setValid(false)
                geometryFieldView?.setValid(true);
                                
                expect(geometryFieldView?.mapView.isHidden).to(beTrue());
                expect(geometryFieldView?.textField.text) == "";
                expect(geometryFieldView?.textField.label.text) == "Field Title"
                expect(geometryFieldView?.textField.textColor) != MAGEScheme.scheme().colorScheme.errorColor;
            }

            it("required field is invalid if empty") {
                field[FieldKey.required.key] = true;
                
                geometryFieldView = GeometryView(field: field);
                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());

                expect(geometryFieldView?.isEmpty()) == true;
                expect(geometryFieldView?.isValid(enforceRequired: true)) == false;
                
                expect(geometryFieldView?.mapView.isHidden).to(beTrue());
                expect(geometryFieldView?.textField.text) == "";
                expect(geometryFieldView?.textField.label.text) == "Field Title *"
            }

            it("required field is valid if not empty") {
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                field[FieldKey.required.key] = true;
                
                geometryFieldView = GeometryView(field: field, value: point);
                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
                
                expect(geometryFieldView?.isEmpty()) == false;
                expect(geometryFieldView?.isValid(enforceRequired: true)) == true;
                
                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
                expect(geometryFieldView?.textField.text) == "40.00850, -105.26780 ";
                expect(geometryFieldView?.textField.label.text) == "Field Title *"
            }
            
            it("set value via input") {
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
                expect((viewTester().usingLabel("\(field[FieldKey.name.key] as? String ?? "") value")!.view as! MDCFilledTextField).text) == "1.00000, 1.00000 "
                
                expect(UIApplication.getTopViewController()).toNot(beAnInstanceOf(delegate.viewControllerToLaunch!.classForCoder));
                
                nc.popToRootViewController(animated: false);
                window.rootViewController = controller;
            }
            
            it("copy location") {
                let expectation: XCTestExpectation = self.expectation(description: "Wait for map rendering")

                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    expectation.fulfill()
                }
                                
                let mockActionsDelegate: MockObservationActionsDelegate = MockObservationActionsDelegate();
                
                geometryFieldView = GeometryView(field: field, editMode: false, value: point, accuracy: 100.487235, provider: "gps", mapEventDelegate: mockMapDelegate, observationActionsDelegate: mockActionsDelegate);
                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView!)
                geometryFieldView?.autoPinEdgesToSuperviewEdges();
                                
                let result: XCTWaiter.Result = XCTWaiter.wait(for: [expectation], timeout: 5.0)
                XCTAssertEqual(result, .completed)
                
                expect(geometryFieldView?.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                expect(geometryFieldView?.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                expect(geometryFieldView?.latitudeLongitudeButton.currentTitle) == "40.00850, -105.26780";
                expect(geometryFieldView?.latitudeLongitudeButton.isEnabled).to(beTrue());
                expect(geometryFieldView?.accuracyLabel.text) == "GPS ± 100.49m";
                expect(geometryFieldView?.fieldNameLabel.text) == "Field Title"
                
                tester().tapView(withAccessibilityLabel: "location field8");
                expect(mockActionsDelegate.copyLocationCalled).to(beTrue());
                expect(mockActionsDelegate.locationStringCopied) == "40.00850, -105.26780";
            }
        }
    }
}

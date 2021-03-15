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
import Nimble_Snapshots

@testable import MAGE

class GeometryViewTests: KIFSpec {
    
    override func spec() {
        
        describe("GeometryView") {
            var field: [String: Any]!
            let recordSnapshots = false;
            Nimble_Snapshots.setNimbleTolerance(0.1);
            
            var geometryFieldView: GeometryView!
            var view: UIView!
            var controller: ContainingUIViewController!
            var window: UIWindow!;
            
            func maybeRecordSnapshot(_ view: UIView, recordThisSnapshot: Bool = false, doneClosure: (() -> Void)?) {
                print("Record snapshot?", recordSnapshots);
                if (recordSnapshots || recordThisSnapshot) {
                    DispatchQueue.global(qos: .userInitiated).async {
                        Thread.sleep(forTimeInterval: 5.0);
                        DispatchQueue.main.async {
                            expect(view) == recordSnapshot(usesDrawRect: true);
                            doneClosure?();
                        }
                    }
                } else {
                    doneClosure?();
                }
            }
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();

                window = UIWindow(forAutoLayout: ());
                window.autoSetDimension(.width, toSize: 300);

                controller = ContainingUIViewController();
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
                view.backgroundColor = .systemBackground;
                window.makeKeyAndVisible();

                field = [
                    "title": "Field Title",
                    "name": "field8",
                    "type": "geometry",
                    "id": 8
                ];
                
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.showMGRS = false;
            }
            
            afterEach {
                controller.dismiss(animated: false, completion: nil);
                window.rootViewController = nil;
                geometryFieldView.removeFromSuperview();
                
                controller = nil;
                view = nil;
                window = nil;
                
                geometryFieldView = nil;
                
//                tester().wait(forTimeInterval: 2.0);
                TestHelpers.clearAndSetUpStack();
            }
            
            it("no initial value") {
                let mockMapDelegate: MockMapViewDelegate = MockMapViewDelegate()

                controller.viewDidLoadClosure = {
                    geometryFieldView = GeometryView(field: field, mapEventDelegate: mockMapDelegate);
                    geometryFieldView.applyTheme(withScheme: MAGEScheme.scheme());

                    view.addSubview(geometryFieldView)
                    geometryFieldView.autoPinEdgesToSuperviewEdges();
                    
                    expect(geometryFieldView.latitudeLongitudeButton.currentTitle) == "NO LOCATION SET";
                    expect(geometryFieldView.latitudeLongitudeButton.isEnabled).to(beFalse());
                    expect(geometryFieldView.accuracyLabel.text).to(beNil());
                    expect(geometryFieldView.fieldNameLabel.text) == "Field Title (Lat, Long)"
                    expect(geometryFieldView.fieldNameSpacerView.superview).toNot(beNil());
                }

                window.rootViewController = controller;
                controller.view.addSubview(view);
            }
            
            it("non edit mode reference image") {
                var completeTest = false;
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    maybeRecordSnapshot(view, doneClosure: {
                        tester().waitForAnimationsToFinish();
                        expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                        expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                        completeTest = true;
                    })
                }
                
                window.rootViewController = controller;
                
                geometryFieldView = GeometryView(field: field, editMode: false, value: point, accuracy: 100.487235, provider: "gps", mapEventDelegate: mockMapDelegate);
                geometryFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(geometryFieldView.latitudeLongitudeButton.currentTitle) == "40.00850, -105.26780";
                expect(geometryFieldView.latitudeLongitudeButton.isEnabled).to(beTrue());
                expect(geometryFieldView.accuracyLabel.text) == "GPS ± 100.49m";
                expect(geometryFieldView.fieldNameLabel.text) == "Field Title (Lat, Long)"
                expect(geometryFieldView.fieldNameLabel.superview).toNot(beNil());
                expect(geometryFieldView.editFab.superview).to(beNil());
                
                controller.view.addSubview(view);
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("non edit mode initial value set as a point") {
                var completeTest = false;
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    tester().waitForAnimationsToFinish();
                    expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    completeTest = true;
                }
                
                window.rootViewController = controller;
                
                geometryFieldView = GeometryView(field: field, editMode: false, value: point, accuracy: 100.487235, provider: "gps", mapEventDelegate: mockMapDelegate);
                geometryFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                controller.view.addSubview(view);
                
                expect(geometryFieldView.latitudeLongitudeButton.currentTitle) == "40.00850, -105.26780";
                expect(geometryFieldView.latitudeLongitudeButton.isEnabled).to(beTrue());
                expect(geometryFieldView.accuracyLabel.text) == "GPS ± 100.49m";
                expect(geometryFieldView.fieldNameLabel.text) == "Field Title (Lat, Long)"
                expect(geometryFieldView.fieldNameLabel.superview).toNot(beNil());
                expect(geometryFieldView.editFab.superview).to(beNil());
                expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
            }
            
            it("edit mode reference image") {
                var completeTest = false;
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    maybeRecordSnapshot(view, doneClosure: {
                        tester().waitForAnimationsToFinish();
                        expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                        expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                        completeTest = true;
                    })
                }
                
                window.rootViewController = controller;
                
                geometryFieldView = GeometryView(field: field, value: point, accuracy: 100.487235, provider: "gps", mapEventDelegate: mockMapDelegate);
                geometryFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                
                expect(geometryFieldView.latitudeLongitudeButton.currentTitle) == "40.00850, -105.26780";
                expect(geometryFieldView.latitudeLongitudeButton.isEnabled).to(beTrue());
                expect(geometryFieldView.accuracyLabel.text) == "GPS ± 100.49m";
                expect(geometryFieldView.fieldNameLabel.text) == "Field Title (Lat, Long)"
                expect(geometryFieldView.fieldNameSpacerView.superview).toNot(beNil());
                expect(geometryFieldView.editFab.superview).toNot(beNil());
                
                controller.view.addSubview(view);
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }

            it("initial value set as a point") {
                var completeTest = false;
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()

                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    tester().waitForAnimationsToFinish();
                    expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    completeTest = true;
                }

                window.rootViewController = controller;
                
                geometryFieldView = GeometryView(field: field, value: point, accuracy: 100.487235, provider: "gps", mapEventDelegate: mockMapDelegate);
                geometryFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                controller.view.addSubview(view);
                
                expect(geometryFieldView.latitudeLongitudeButton.currentTitle) == "40.00850, -105.26780";
                expect(geometryFieldView.latitudeLongitudeButton.isEnabled).to(beTrue());
                expect(geometryFieldView.accuracyLabel.text) == "GPS ± 100.49m";
                expect(geometryFieldView.fieldNameLabel.text) == "Field Title (Lat, Long)"
                expect(geometryFieldView.fieldNameSpacerView.superview).toNot(beNil());
                expect(geometryFieldView.editFab.superview).toNot(beNil());
                expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
            }
            
            it("initial value set as a point no title") {
                var completeTest = false;
                field[FieldKey.title.key] = nil;
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    tester().waitForAnimationsToFinish();
                    expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    completeTest = true;
                }
                
                window.rootViewController = controller;
                
                geometryFieldView = GeometryView(field: field, value: point, accuracy: 100.487235, provider: "gps", mapEventDelegate: mockMapDelegate);
                geometryFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                controller.view.addSubview(view);
                
                expect(geometryFieldView.latitudeLongitudeButton.currentTitle) == "40.00850, -105.26780";
                expect(geometryFieldView.latitudeLongitudeButton.isEnabled).to(beTrue());
                expect(geometryFieldView.accuracyLabel.text) == "GPS ± 100.49m";
                expect(geometryFieldView.fieldNameLabel.text) == "";
                expect(geometryFieldView.fieldNameSpacerView.superview).to(beNil());
                expect(geometryFieldView.editFab.superview).toNot(beNil());
                expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
            }
            
            it("initial value set as a point MGRS") {
                var completeTest = false;
                UserDefaults.standard.set(true, forKey: "showMGRS");
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    completeTest = true;
                }
                
                window.rootViewController = controller;
                
                geometryFieldView = GeometryView(field: field, value: point, accuracy: 100.487235, provider: "gps", mapEventDelegate: mockMapDelegate);
                geometryFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                controller.view.addSubview(view);
                
                expect(geometryFieldView.latitudeLongitudeButton.currentTitle) == "13TDE7714328735";
                expect(geometryFieldView.latitudeLongitudeButton.isEnabled).to(beTrue());
                expect(geometryFieldView.accuracyLabel.text) == "GPS ± 100.49m";
                expect(geometryFieldView.fieldNameLabel.text) == "Field Title (MGRS)";
                expect(geometryFieldView.fieldNameSpacerView.superview).toNot(beNil());
                expect(geometryFieldView.editFab.superview).toNot(beNil());
                
                expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
            }
            
            it("initial value set wtih observation without geometry") {
                let observation: Observation = ObservationBuilder.createBlankObservation()
                let eventForms: [[String : Any]] = [FormBuilder.createEmptyForm()];
                
                let mockMapDelegate = MockMapViewDelegate()

                window.rootViewController = controller;
                
                geometryFieldView = GeometryView(field: field, observation: observation, eventForms: eventForms , mapEventDelegate: mockMapDelegate);
                geometryFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();

                expect(geometryFieldView.latitudeLongitudeButton.currentTitle) == "NO LOCATION SET";
                expect(geometryFieldView.latitudeLongitudeButton.isEnabled).to(beFalse());
                expect(geometryFieldView.accuracyLabel.text).to(beNil());
                expect(geometryFieldView.fieldNameLabel.text) == "Field Title (Lat, Long)";
                expect(geometryFieldView.fieldNameSpacerView.superview).toNot(beNil());
                expect(geometryFieldView.editFab.superview).toNot(beNil());
            }
            
            it("initial value set wtih observation") {
                var completeTest = false;
                let observation: Observation = ObservationBuilder.createPointObservation();
                let eventForms: [[String : Any]] = [FormBuilder.createEmptyForm()];

                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    let point: SFPoint = observation.getGeometry().centroid();
                    expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    tester().waitForView(withAccessibilityLabel: "Observation Annotation \(observation.objectID.uriRepresentation())");
                    completeTest = true;
                }
                
                window.rootViewController = controller;
                
                geometryFieldView = GeometryView(field: field, observation: observation, eventForms: eventForms , mapEventDelegate: mockMapDelegate);
                geometryFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                controller.view.addSubview(view);
                
                expect(geometryFieldView.latitudeLongitudeButton.currentTitle) == "40.00850, -105.26780";
                expect(geometryFieldView.latitudeLongitudeButton.isEnabled).to(beTrue());
                expect(geometryFieldView.accuracyLabel.text).to(beNil());
                expect(geometryFieldView.fieldNameLabel.text) == "Field Title (Lat, Long)";
                expect(geometryFieldView.fieldNameSpacerView.superview).toNot(beNil());
                expect(geometryFieldView.editFab.superview).toNot(beNil());
                expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
            }
            
            it("initial value set wtih observation with accuracy") {
                var completeTest = false;
                let observation: Observation = ObservationBuilder.createPointObservation();
                ObservationBuilder.addObservationProperty(observation: observation, key: "accuracy", value: 100.487235)
                let eventForms: [[String : Any]] = [FormBuilder.createEmptyForm()]
                
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    let point: SFPoint = observation.getGeometry().centroid();
                    expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    tester().waitForView(withAccessibilityLabel: "Observation Annotation \(observation.objectID.uriRepresentation())");
                    completeTest = true;
                }
                
                window.rootViewController = controller;
                
                geometryFieldView = GeometryView(field: field, observation: observation, eventForms: eventForms, mapEventDelegate: mockMapDelegate);
                geometryFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                
                expect(geometryFieldView.latitudeLongitudeButton.currentTitle) == "40.00850, -105.26780";
                expect(geometryFieldView.latitudeLongitudeButton.isEnabled).to(beTrue());
                expect(geometryFieldView.accuracyLabel.text) == " ± 100.49m";
                expect(geometryFieldView.fieldNameLabel.text) == "Field Title (Lat, Long)";
                expect(geometryFieldView.fieldNameSpacerView.superview).toNot(beNil());
                expect(geometryFieldView.editFab.superview).toNot(beNil());
                
                expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
            }
            
            it("initial value set wtih observation with accuracy and provider") {
                var completeTest = false;
                let observation: Observation = ObservationBuilder.createPointObservation();
                ObservationBuilder.addObservationProperty(observation: observation, key: "accuracy", value: 100.487235)
                ObservationBuilder.addObservationProperty(observation: observation, key: "provider", value: "gps")
                let eventForms: [[String : Any]] = [FormBuilder.createEmptyForm()];
                
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    tester().waitForAnimationsToFinish();
                    let point: SFPoint = observation.getGeometry().centroid();
                    expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    tester().waitForView(withAccessibilityLabel: "Observation Annotation \(observation.objectID.uriRepresentation())");
                    completeTest = true;
                }
                
                window.rootViewController = controller;
                
                geometryFieldView = GeometryView(field: field, observation: observation, eventForms: eventForms , mapEventDelegate: mockMapDelegate);
                geometryFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                
                expect(geometryFieldView.latitudeLongitudeButton.currentTitle) == "40.00850, -105.26780";
                expect(geometryFieldView.latitudeLongitudeButton.isEnabled).to(beTrue());
                expect(geometryFieldView.accuracyLabel.text) == "GPS ± 100.49m";
                expect(geometryFieldView.fieldNameLabel.text) == "Field Title (Lat, Long)";
                expect(geometryFieldView.fieldNameSpacerView.superview).toNot(beNil());
                expect(geometryFieldView.editFab.superview).toNot(beNil());
                
                expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
            }
            
            it("initial value set wtih observation line") {
                var completeTest = false;
                
                let observation: Observation = ObservationBuilder.createLineObservation();
                let eventForms: [[String : Any]] = [FormBuilder.createEmptyForm()];

                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    let point: SFPoint = observation.getGeometry().centroid();
                    expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    completeTest = true;
                }
                
                window.rootViewController = controller;
                
                geometryFieldView = GeometryView(field: field, observation: observation, eventForms: eventForms, mapEventDelegate: mockMapDelegate);
                geometryFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                expect(geometryFieldView.latitudeLongitudeButton.currentTitle) == "40.00850, -105.26655";
                expect(geometryFieldView.latitudeLongitudeButton.isEnabled).to(beTrue());
                expect(geometryFieldView.accuracyLabel.text).to(beNil());
                expect(geometryFieldView.fieldNameLabel.text) == "Field Title (Lat, Long)";
                expect(geometryFieldView.fieldNameSpacerView.superview).toNot(beNil());
                expect(geometryFieldView.editFab.superview).toNot(beNil());
                
                expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
            }
            
            it("initial value set wtih observation polygon") {
                var completeTest = false;
                
                let observation: Observation = ObservationBuilder.createPolygonObservation();
                let eventForms: [[String : Any]] = [FormBuilder.createEmptyForm()];

                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    let point: SFPoint = observation.getGeometry().centroid();
                    expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    completeTest = true;
                }
                
                window.rootViewController = controller;
                
                geometryFieldView = GeometryView(field: field, observation: observation, eventForms: eventForms, mapEventDelegate: mockMapDelegate);
                geometryFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                
                expect(geometryFieldView.latitudeLongitudeButton.currentTitle) == "40.00935, -105.26655";
                expect(geometryFieldView.latitudeLongitudeButton.isEnabled).to(beTrue());
                expect(geometryFieldView.accuracyLabel.text).to(beNil());
                expect(geometryFieldView.fieldNameLabel.text) == "Field Title (Lat, Long)";
                expect(geometryFieldView.fieldNameSpacerView.superview).toNot(beNil());
                expect(geometryFieldView.editFab.superview).toNot(beNil());
                
                expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
            }
            
            it("set value later wtih observation with accuracy and provider") {
                var completeTest = false;
                let observation: Observation = ObservationBuilder.createPointObservation();
                ObservationBuilder.addObservationProperty(observation: observation, key: "accuracy", value: 100.487235)
                ObservationBuilder.addObservationProperty(observation: observation, key: "provider", value: "gps")
                let eventForms: [[String : Any]] = [FormBuilder.createEmptyForm()];
                
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    tester().waitForAnimationsToFinish();
                    let point: SFPoint = observation.getGeometry().centroid();
                    expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    tester().waitForView(withAccessibilityLabel: "Observation Annotation \(observation.objectID.uriRepresentation())");
                    completeTest = true;
                }
                
                window.rootViewController = controller;
                
                geometryFieldView = GeometryView(field: field, observation: nil, eventForms: eventForms , mapEventDelegate: mockMapDelegate);
                geometryFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                
                geometryFieldView.setObservation(observation: observation);
                
                expect(geometryFieldView.latitudeLongitudeButton.currentTitle) == "40.00850, -105.26780";
                expect(geometryFieldView.latitudeLongitudeButton.isEnabled).to(beTrue());
                expect(geometryFieldView.accuracyLabel.text) == "GPS ± 100.49m";
                expect(geometryFieldView.fieldNameLabel.text) == "Field Title (Lat, Long)";
                expect(geometryFieldView.fieldNameSpacerView.superview).toNot(beNil());
                expect(geometryFieldView.editFab.superview).toNot(beNil());
                
                expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
            }

            it("set value later") {
                var completeTest = false;

                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()

                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    completeTest = true;
                }

                controller.viewDidLoadClosure = {
                    geometryFieldView = GeometryView(field: field, mapEventDelegate: mockMapDelegate);
                    geometryFieldView.applyTheme(withScheme: MAGEScheme.scheme());

                    view.addSubview(geometryFieldView)
                    geometryFieldView.autoPinEdgesToSuperviewEdges();

                    geometryFieldView.setValue(point);
                }

                window.rootViewController = controller;
                controller.view.addSubview(view);
                
                expect(geometryFieldView.latitudeLongitudeButton.currentTitle) == "40.00850, -105.26780";
                expect(geometryFieldView.latitudeLongitudeButton.isEnabled).to(beTrue());
                expect(geometryFieldView.accuracyLabel.text).to(beNil());
                expect(geometryFieldView.fieldNameLabel.text) == "Field Title (Lat, Long)";
                expect(geometryFieldView.fieldNameSpacerView.superview).toNot(beNil());
                expect(geometryFieldView.editFab.superview).toNot(beNil());
                
                expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
            }
            
            it("set value later with accuracy") {
                
                var completeTest = false;
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    completeTest = true;
                }
                
                controller.viewDidLoadClosure = {
                    geometryFieldView = GeometryView(field: field, mapEventDelegate: mockMapDelegate);
                    geometryFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                    geometryFieldView.setValue(point, accuracy: 100.487235, provider: "gps");
                    
                    view.addSubview(geometryFieldView)
                    geometryFieldView.autoPinEdgesToSuperviewEdges();
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                
                expect(geometryFieldView.latitudeLongitudeButton.currentTitle) == "40.00850, -105.26780";
                expect(geometryFieldView.latitudeLongitudeButton.isEnabled).to(beTrue());
                expect(geometryFieldView.accuracyLabel.text) == "GPS ± 100.49m";
                expect(geometryFieldView.fieldNameLabel.text) == "Field Title (Lat, Long)";
                expect(geometryFieldView.fieldNameSpacerView.superview).toNot(beNil());
                expect(geometryFieldView.editFab.superview).toNot(beNil());
                
                expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
            }
            
            it("set value later with accuracy and no provider") {
                
                var completeTest = false;
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    completeTest = true;
                }
                
                controller.viewDidLoadClosure = {
                    geometryFieldView = GeometryView(field: field, mapEventDelegate: mockMapDelegate);
                    geometryFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                    geometryFieldView.setValue(point, accuracy: 100.487235);
                    
                    view.addSubview(geometryFieldView)
                    geometryFieldView.autoPinEdgesToSuperviewEdges();
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                
                expect(geometryFieldView.latitudeLongitudeButton.currentTitle) == "40.00850, -105.26780";
                expect(geometryFieldView.latitudeLongitudeButton.isEnabled).to(beTrue());
                expect(geometryFieldView.accuracyLabel.text) == " ± 100.49m";
                expect(geometryFieldView.fieldNameLabel.text) == "Field Title (Lat, Long)";
                expect(geometryFieldView.fieldNameSpacerView.superview).toNot(beNil());
                expect(geometryFieldView.editFab.superview).toNot(beNil());
                
                expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
            }

            it("set valid false") {
                var completeTest = false;
                
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    maybeRecordSnapshot(view, doneClosure: {
                        completeTest = true;
                    })
                }
                
                window.rootViewController = controller;
                
                geometryFieldView = GeometryView(field: field, mapEventDelegate: mockMapDelegate);
                geometryFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                geometryFieldView.setValid(false);

                controller.view.addSubview(view);
                
                expect(geometryFieldView.latitudeLongitudeButton.currentTitle) == "NO LOCATION SET";
                expect(geometryFieldView.latitudeLongitudeButton.isEnabled).to(beFalse());
                expect(geometryFieldView.accuracyLabel.text).to(beNil());
                expect(geometryFieldView.fieldNameLabel.text) == "Field Title (Lat, Long)";
                expect(geometryFieldView.fieldNameLabel.textColor) == MAGEScheme.scheme().colorScheme.errorColor;
                expect(geometryFieldView.fieldNameSpacerView.superview).toNot(beNil());
                expect(geometryFieldView.editFab.superview).toNot(beNil());
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }

            it("set valid true after being invalid") {
                
                let mockMapDelegate = MockMapViewDelegate()
                
                window.rootViewController = controller;
                
                geometryFieldView = GeometryView(field: field, mapEventDelegate: mockMapDelegate);
                geometryFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                geometryFieldView.setValid(false);
                geometryFieldView.setValid(true);
                
                controller.view.addSubview(view);
                
                expect(geometryFieldView.latitudeLongitudeButton.currentTitle) == "NO LOCATION SET";
                expect(geometryFieldView.latitudeLongitudeButton.isEnabled).to(beFalse());
                expect(geometryFieldView.accuracyLabel.text).to(beNil());
                expect(geometryFieldView.fieldNameLabel.text) == "Field Title (Lat, Long)";
                expect(geometryFieldView.fieldNameSpacerView.superview).toNot(beNil());
                expect(geometryFieldView.editFab.superview).toNot(beNil());
                expect(geometryFieldView.fieldNameLabel.textColor) != MAGEScheme.scheme().colorScheme.errorColor;
            }

            it("required field is invalid if empty") {
                field[FieldKey.required.key] = true;
                
                geometryFieldView = GeometryView(field: field);
                geometryFieldView.applyTheme(withScheme: MAGEScheme.scheme());

                expect(geometryFieldView.isEmpty()) == true;
                expect(geometryFieldView.isValid(enforceRequired: true)) == false;
                
                expect(geometryFieldView.latitudeLongitudeButton.currentTitle) == "NO LOCATION SET";
                expect(geometryFieldView.latitudeLongitudeButton.isEnabled).to(beFalse());
                expect(geometryFieldView.accuracyLabel.text).to(beNil());
                expect(geometryFieldView.fieldNameLabel.text) == "Field Title (Lat, Long) *";
                expect(geometryFieldView.fieldNameSpacerView.superview).toNot(beNil());
                expect(geometryFieldView.editFab.superview).toNot(beNil());
            }

            it("required field is valid if not empty") {
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                field[FieldKey.required.key] = true;
                
                geometryFieldView = GeometryView(field: field, value: point);
                geometryFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                expect(geometryFieldView.isEmpty()) == false;
                expect(geometryFieldView.isValid(enforceRequired: true)) == true;
                
                expect(geometryFieldView.latitudeLongitudeButton.currentTitle) == "40.00850, -105.26780";
                expect(geometryFieldView.latitudeLongitudeButton.isEnabled).to(beTrue());
                expect(geometryFieldView.accuracyLabel.text).to(beNil());
                expect(geometryFieldView.fieldNameLabel.text) == "Field Title (Lat, Long) *";
                expect(geometryFieldView.fieldNameSpacerView.superview).toNot(beNil());
                expect(geometryFieldView.editFab.superview).toNot(beNil());
            }
            
            it("set value via input") {
                let delegate = MockFieldDelegate();
                
                let nc = UINavigationController(rootViewController: controller);
                
                window.rootViewController = nc;
                
                geometryFieldView = GeometryView(field: field, delegate: delegate);
                geometryFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view = view;
                tester().waitForView(withAccessibilityLabel: field[FieldKey.name.key] as? String);
                geometryFieldView.handleTap();
                expect(delegate.launchFieldSelectionViewControllerCalled).to(beTrue());
                expect(delegate.viewControllerToLaunch).to(beAnInstanceOf(GeometryEditViewController.self));
                
                nc.pushViewController(delegate.viewControllerToLaunch!, animated: false);
                tester().tapView(withAccessibilityLabel: "Done");
                expect((viewTester().usingLabel("location field8")!.view as! MDCButton).currentTitle) == "1.00000, 1.00000"
                
                expect(UIApplication.getTopViewController()).toNot(beAnInstanceOf(delegate.viewControllerToLaunch!.classForCoder));
                
                nc.popToRootViewController(animated: false);
            }
            
            it("copy location") {
                var completeTest = false;
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    tester().waitForAnimationsToFinish();
                    expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                    expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                    completeTest = true;
                }
                
                window.rootViewController = controller;
                
                let mockActionsDelegate: MockObservationActionsDelegate = MockObservationActionsDelegate();
                
                geometryFieldView = GeometryView(field: field, value: point, accuracy: 100.487235, provider: "gps", mapEventDelegate: mockMapDelegate, observationActionsDelegate: mockActionsDelegate);
                geometryFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                controller.view.addSubview(view);
                
                expect(geometryFieldView.latitudeLongitudeButton.currentTitle) == "40.00850, -105.26780";
                expect(geometryFieldView.latitudeLongitudeButton.isEnabled).to(beTrue());
                expect(geometryFieldView.accuracyLabel.text) == "GPS ± 100.49m";
                expect(geometryFieldView.fieldNameLabel.text) == "Field Title (Lat, Long)"
                expect(geometryFieldView.fieldNameSpacerView.superview).toNot(beNil());
                expect(geometryFieldView.editFab.superview).toNot(beNil());
                
                tester().tapView(withAccessibilityLabel: "location field8");
                expect(mockActionsDelegate.copyLocationCalled).to(beTrue());
                expect(mockActionsDelegate.locationStringCopied) == "40.00850, -105.26780";
                
                expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
            }
        }
    }
}

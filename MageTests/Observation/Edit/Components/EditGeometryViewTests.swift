//
//  EditGeometryViewTests.swift
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

class EditGeometryViewTests: KIFSpec {
    
    override func spec() {
        
        describe("EditGeometryView") {
            var field: [String: Any]!
            let recordSnapshots = false;
            Nimble_Snapshots.setNimbleTolerance(0.1);
            
            var geometryFieldView: EditGeometryView!
            var view: UIView!
            var controller: ContainingUIViewController!
            var window: UIWindow!;
            
            func maybeRecordSnapshot(_ view: UIView, recordThisSnapshot: Bool = false, doneClosure: (() -> Void)?) {
                print("Record snapshot?", recordSnapshots);
                if (recordSnapshots || recordThisSnapshot) {
                    DispatchQueue.global(qos: .userInitiated).async {
                        Thread.sleep(forTimeInterval: 5.0);
                        DispatchQueue.main.async {
                            expect(view) == recordSnapshot();
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
                    "id": 8
                ];
                
                UserDefaults.standard.set(0, forKey: "mapType");
                UserDefaults.standard.set(false, forKey: "showMGRS");
                UserDefaults.standard.synchronize();
            }
            
            afterEach {
                controller.dismiss(animated: false, completion: nil);
                window.rootViewController = nil;
//                geometryFieldView.removeFromSuperview();
                
                controller = nil;
                view = nil;
                window = nil;
                
                geometryFieldView = nil;
                
//                tester().wait(forTimeInterval: 2.0);
                TestHelpers.clearAndSetUpStack();
            }
            
            it("no initial value") {
                var completeTest = false;

                let mockMapDelegate: MockMapViewDelegate = MockMapViewDelegate()

                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullRendered in
                    maybeRecordSnapshot(view, doneClosure: {
                        completeTest = true;
                    })
                }

                controller.viewDidLoadClosure = {
                    geometryFieldView = EditGeometryView(field: field, mapEventDelegate: mockMapDelegate);

                    view.addSubview(geometryFieldView)
                    geometryFieldView.autoPinEdgesToSuperviewEdges();
                }

                window.rootViewController = controller;
                controller.view.addSubview(view);
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }

            it("initial value set as a point") {
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
                
                geometryFieldView = EditGeometryView(field: field, value: point, accuracy: 100.487235, provider: "gps", mapEventDelegate: mockMapDelegate);
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("initial value set as a point MGRS") {
                UserDefaults.standard.set(true, forKey: "showMGRS");
                UserDefaults.standard.synchronize();
                var completeTest = false;
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    maybeRecordSnapshot(view, doneClosure: {
                        expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                        expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                        completeTest = true;
                    })
                }
                
                window.rootViewController = controller;
                
                geometryFieldView = EditGeometryView(field: field, value: point, accuracy: 100.487235, provider: "gps", mapEventDelegate: mockMapDelegate);
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("initial value set wtih observation without geometry") {
                var completeTest = false;
                let observation: Observation = ObservationBuilder.createBlankObservation()
                let eventForms: [[String : Any]] = [FormBuilder.createEmptyForm()];
                
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    maybeRecordSnapshot(view, doneClosure: {
                        completeTest = true;
                    })
                }
                
                window.rootViewController = controller;
                
                geometryFieldView = EditGeometryView(field: field, observation: observation, eventForms: eventForms , mapEventDelegate: mockMapDelegate);
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("initial value set wtih observation") {
                var completeTest = false;
                let observation: Observation = ObservationBuilder.createPointObservation();
                let eventForms: [[String : Any]] = [FormBuilder.createEmptyForm()];

                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    maybeRecordSnapshot(view, doneClosure: {
                        let point: SFPoint = observation.getGeometry().centroid();
                        expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                        expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                        completeTest = true;
                    })
                }
                
                window.rootViewController = controller;
                
                geometryFieldView = EditGeometryView(field: field, observation: observation, eventForms: eventForms , mapEventDelegate: mockMapDelegate);
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("initial value set wtih observation with accuracy") {
                var completeTest = false;
                let observation: Observation = ObservationBuilder.createPointObservation();
                ObservationBuilder.addObservationProperty(observation: observation, key: "accuracy", value: 100.487235)
                let eventForms: [[String : Any]] = [FormBuilder.createEmptyForm()]
                
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    maybeRecordSnapshot(view, doneClosure: {
                        let point: SFPoint = observation.getGeometry().centroid();
                        expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                        expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                        completeTest = true;
                    })
                }
                
                window.rootViewController = controller;
                
                geometryFieldView = EditGeometryView(field: field, observation: observation, eventForms: eventForms , mapEventDelegate: mockMapDelegate);
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("initial value set wtih observation with accuracy and provider") {
                var completeTest = false;
                let observation: Observation = ObservationBuilder.createPointObservation();
                ObservationBuilder.addObservationProperty(observation: observation, key: "accuracy", value: 100.487235)
                ObservationBuilder.addObservationProperty(observation: observation, key: "provider", value: "gps")
                let eventForms: [[String : Any]] = [FormBuilder.createEmptyForm()];
                
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    maybeRecordSnapshot(view, doneClosure: {
                        tester().waitForAnimationsToFinish();
                        let point: SFPoint = observation.getGeometry().centroid();
                        expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                        expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                        completeTest = true;
                    })
                }
                
                window.rootViewController = controller;
                
                geometryFieldView = EditGeometryView(field: field, observation: observation, eventForms: eventForms , mapEventDelegate: mockMapDelegate);
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("initial value set wtih observation line") {
                var completeTest = false;
                
                let observation: Observation = ObservationBuilder.createLineObservation();
                let eventForms: [[String : Any]] = [FormBuilder.createEmptyForm()];

                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    maybeRecordSnapshot(view, doneClosure: {
                        let point: SFPoint = observation.getGeometry().centroid();
                        expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                        expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                        completeTest = true;
                    })
                }
                
                window.rootViewController = controller;
                
                geometryFieldView = EditGeometryView(field: field, observation: observation, eventForms: eventForms, mapEventDelegate: mockMapDelegate);
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("initial value set wtih observation polygon") {
                var completeTest = false;
                
                let observation: Observation = ObservationBuilder.createPolygonObservation();
                let eventForms: [[String : Any]] = [FormBuilder.createEmptyForm()];
                print("EventFOrms", eventForms);

                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    maybeRecordSnapshot(view, doneClosure: {
                        let point: SFPoint = observation.getGeometry().centroid();
                        expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                        expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                        completeTest = true;
                    })
                }
                
                window.rootViewController = controller;
                
                geometryFieldView = EditGeometryView(field: field, observation: observation, eventForms: eventForms, mapEventDelegate: mockMapDelegate);
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }

            it("set value later") {
                
                var completeTest = false;

                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()

                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    maybeRecordSnapshot(view, doneClosure: {
                        expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                        expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                        completeTest = true;
                    })
                }

                controller.viewDidLoadClosure = {
                    geometryFieldView = EditGeometryView(field: field, mapEventDelegate: mockMapDelegate);

                    view.addSubview(geometryFieldView)
                    geometryFieldView.autoPinEdgesToSuperviewEdges();

                    geometryFieldView.setValue(point);
                }

                window.rootViewController = controller;
                controller.view.addSubview(view);
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("set value later with accuracy") {
                
                var completeTest = false;
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    maybeRecordSnapshot(view, doneClosure: {
                        expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                        expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                        completeTest = true;
                    })
                }
                
                controller.viewDidLoadClosure = {
                    geometryFieldView = EditGeometryView(field: field, mapEventDelegate: mockMapDelegate);
                    geometryFieldView.setValue(point, accuracy: 100.487235, provider: "gps");
                    
                    view.addSubview(geometryFieldView)
                    geometryFieldView.autoPinEdgesToSuperviewEdges();
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("set value later with accuracy and no provider") {
                
                var completeTest = false;
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    maybeRecordSnapshot(view, doneClosure: {
                        expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
                        expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
                        completeTest = true;
                    })
                }
                
                controller.viewDidLoadClosure = {
                    geometryFieldView = EditGeometryView(field: field, mapEventDelegate: mockMapDelegate);
                    geometryFieldView.setValue(point, accuracy: 100.487235);
                    
                    view.addSubview(geometryFieldView)
                    geometryFieldView.autoPinEdgesToSuperviewEdges();
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
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
                
                geometryFieldView = EditGeometryView(field: field, mapEventDelegate: mockMapDelegate);
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                geometryFieldView.setValid(false);

                controller.view.addSubview(view);
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }

            it("set valid true after being invalid") {
                var completeTest = false;
                
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    maybeRecordSnapshot(view, doneClosure: {
                        completeTest = true;
                    })
                }
                
                window.rootViewController = controller;
                
                geometryFieldView = EditGeometryView(field: field, mapEventDelegate: mockMapDelegate);
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                geometryFieldView.setValid(false);
                geometryFieldView.setValid(true);
                
                controller.view.addSubview(view);
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }

            it("required field is invalid if empty") {
                field[FieldKey.required.key] = true;
                
                geometryFieldView = EditGeometryView(field: field);

                expect(geometryFieldView.isEmpty()) == true;
                expect(geometryFieldView.isValid(enforceRequired: true)) == false;
            }

            it("required field is valid if not empty") {
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                field[FieldKey.required.key] = true;
                
                geometryFieldView = EditGeometryView(field: field, value: point);
                
                expect(geometryFieldView.isEmpty()) == false;
                expect(geometryFieldView.isValid(enforceRequired: true)) == true;
            }

            it("required field has title which indicates required") {
                field[FieldKey.required.key] = true;
                var completeTest = false;
                
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    maybeRecordSnapshot(view, doneClosure: {
                        completeTest = true;
                    })
                }
                
                window.rootViewController = controller;
                
                geometryFieldView = EditGeometryView(field: field, mapEventDelegate: mockMapDelegate);
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("set value via input") {
                let delegate = MockFieldDelegate();
                
                window.rootViewController = controller;
                
                geometryFieldView = EditGeometryView(field: field, delegate: delegate);
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view = view;
                tester().waitForView(withAccessibilityLabel: field[FieldKey.name.key] as? String);
                geometryFieldView.handleTap(sender: UITapGestureRecognizer());
                expect(delegate.fieldSelectedCalled).to(beTrue());
                expect(delegate.selectedField).toNot(beNil());
            }
        }
    }
}

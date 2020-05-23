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

class MockGeometryFieldDelegate: NSObject, ObservationEditListener {
    var fieldChangedCalled = false;
    var newValue: String? = nil;
    func observationField(_ field: Any!, valueChangedTo value: Any!, reloadCell reload: Bool) {
        fieldChangedCalled = true;
        newValue = value as? String;
    }
}

class MockMapViewDelegate: NSObject, MKMapViewDelegate {
    var mapDidStartLoadingMapClosure: ((MKMapView) -> Void)?
    var mapDidFinishLoadingClosure: ((MKMapView) -> Void)?
    var mapDidFinishRenderingClosure: ((MKMapView, Bool) -> Void)?
    var mapDidAddOverlayViewsClosure: ((MKMapView) -> Void)?
    
    func mapViewWillStartLoadingMap(_ mapView: MKMapView) {
        mapDidStartLoadingMapClosure?(mapView);
    }
    func mapViewDidFinishLoadingMap(_ mapView: MKMapView) {
        //loading done
        mapDidFinishLoadingClosure?(mapView)
    }
    
    func mapViewDidFinishRenderingMap(_ mapView: MKMapView, fullyRendered: Bool) {
        // rendering done
        mapDidFinishRenderingClosure?(mapView, fullyRendered);
    }
    
    func mapView(_ mapView: MKMapView, didAddOverlayViews overlayViews: [Any]) {
        // added overlay views
        mapDidAddOverlayViewsClosure?(mapView);
    }
}

class ContainingUIViewController: UIViewController {
    var viewDidLoadClosure: (() -> Void)?
    
    override func viewWillAppear(_ animated: Bool) {
        viewDidLoadClosure?();
    }
}

class EditGeometryViewTests: QuickSpec {
    
    override func spec() {
        
        describe("EditGeometryView") {
            var field: NSMutableDictionary!
            let recordSnapshots = true;
            
            var geometryFieldView: EditGeometryView!
            var view: UIView!
            var controller: ContainingUIViewController!
            var window: UIWindow!;
            
            func maybeRecordSnapshot(_ view: UIView, doneClosure: (() -> Void)?) {
                if (recordSnapshots) {
                    DispatchQueue.global(qos: .userInitiated).async {
                        Thread.sleep(forTimeInterval: 5.0);
                        DispatchQueue.main.async {
                            expect(view) == recordSnapshot();
                        }
                    }
                } else {
                    doneClosure?();
                }
            }
            
            beforeEach {
                window = UIWindow(forAutoLayout: ());
                window.autoSetDimension(.width, toSize: 300);

                controller = ContainingUIViewController();
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
                window.makeKeyAndVisible();

                field = ["title": "Field Title"];
                
                UserDefaults.standard.set(0, forKey: "mapType");
                UserDefaults.standard.synchronize();
            }
            
            pending("no initial value") {
                var completeTest = false;

                let mockMapDelegate = MockMapViewDelegate()

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
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }

            pending("initial value set as a point") {
                var completeTest = false;

                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()

                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    maybeRecordSnapshot(view, doneClosure: {
                        expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y));
                        expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x));
                        completeTest = true;
                    })
                }

                window.rootViewController = controller;
                
                geometryFieldView = EditGeometryView(field: field, value: point, accuracy: 100.487235, provider: "gps", mapEventDelegate: mockMapDelegate);
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
            
            pending("initial value set wtih observation") {
                var completeTest = false;
                
                let observation: Observation = ObservationBuilder.createPointObservation(jsonFileName: "observation");
                let eventForms: [NSDictionary] = [FormBuilder.createFormWithAllFieldTypes()] as [NSDictionary];

                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    maybeRecordSnapshot(view, doneClosure: {
                        let point: SFPoint = observation.getGeometry().centroid();
                        expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y));
                        expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x));
                        completeTest = true;
                    })
                }
                
                window.rootViewController = controller;
                
                geometryFieldView = EditGeometryView(field: field, observation: observation, eventForms: eventForms , mapEventDelegate: mockMapDelegate);
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
            
            pending("initial value set wtih observation line") {
                var completeTest = false;
                
                let observation: Observation = ObservationBuilder.createLineObservation();
                let eventForms: [NSDictionary] = [FormBuilder.createFormWithAllFieldTypes()] as [NSDictionary];

                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    maybeRecordSnapshot(view, doneClosure: {
                        let point: SFPoint = observation.getGeometry().centroid();
                        expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y));
                        expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x));
                        completeTest = true;
                    })
                }
                
                window.rootViewController = controller;
                
                geometryFieldView = EditGeometryView(field: field, observation: observation, eventForms: eventForms, mapEventDelegate: mockMapDelegate);
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
            
            it("initial value set wtih observation polygon") {
                var completeTest = false;
                
                let observation: Observation = ObservationBuilder.createPolygonObservation();
                let eventForms: [NSDictionary] = [FormBuilder.createFormWithAllFieldTypes()] as [NSDictionary];

                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    maybeRecordSnapshot(view, doneClosure: {
                        let point: SFPoint = observation.getGeometry().centroid();
                        expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y));
                        expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x));
                        completeTest = true;
                    })
                }
                
                window.rootViewController = controller;
                
                geometryFieldView = EditGeometryView(field: field, observation: observation, eventForms: eventForms, mapEventDelegate: mockMapDelegate);
                
                view.addSubview(geometryFieldView)
                geometryFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }

            pending("set value later") {
                
                var completeTest = false;

                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()

                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    maybeRecordSnapshot(view, doneClosure: {
                        expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y));
                        expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x));
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
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
            
            pending("set value later with accuracy") {
                
                var completeTest = false;
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    maybeRecordSnapshot(view, doneClosure: {
                        expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y));
                        expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x));
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
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 5, description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
            
            pending("set value later with accuracy and no provider") {
                
                var completeTest = false;
                
                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
                let mockMapDelegate = MockMapViewDelegate()
                
                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullyRendered in
                    maybeRecordSnapshot(view, doneClosure: {
                        expect(geometryFieldView.mapView.region.center.latitude).to(beCloseTo(point.y));
                        expect(geometryFieldView.mapView.region.center.longitude).to(beCloseTo(point.x));
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
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 5, description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
//
//            it("set valid false") {
//                textFieldView = EditTextFieldView(field: field);
//
//                view.addSubview(textFieldView)
//                textFieldView.autoPinEdgesToSuperviewEdges();
//
//                textFieldView.setValid(false);
//                expect(view) == snapshot();
//            }
//
//            it("set valid true after being invalid") {
//                textFieldView = EditTextFieldView(field: field);
//
//                view.addSubview(textFieldView)
//                textFieldView.autoPinEdgesToSuperviewEdges();
//
//                textFieldView.setValid(false);
//                textFieldView.setValid(true);
//                expect(view) == snapshot();
//            }
//
//            it("required field is invalid if empty") {
//                field.setValue(true, forKey: "required");
//                textFieldView = EditTextFieldView(field: field);
//
//                expect(textFieldView.isEmpty()) == true;
//                expect(textFieldView.isValid(enforceRequired: true)) == false;
//            }
//
//            it("required field is valid if not empty") {
//                field.setValue(true, forKey: "required");
//                textFieldView = EditTextFieldView(field: field, value: "valid");
//
//                expect(textFieldView.isEmpty()) == false;
//                expect(textFieldView.isValid(enforceRequired: true)) == true;
//            }
//
//            it("required field has title which indicates required") {
//                field.setValue(true, forKey: "required");
//                textFieldView = EditTextFieldView(field: field);
//
//                view.addSubview(textFieldView)
//                textFieldView.autoPinEdgesToSuperviewEdges();
//
//                expect(view) == snapshot();
//            }
//
//            it("test delegate") {
//                let delegate = MockTextFieldDelegate();
//                textFieldView = EditTextFieldView(field: field, delegate: delegate);
//                view.addSubview(textFieldView)
//                textFieldView.autoPinEdgesToSuperviewEdges();
//
//                textFieldView.textField.text = "new value";
//                textFieldView.textFieldDidEndEditing(textFieldView.textField);
//                expect(delegate.fieldChangedCalled) == true;
//                expect(delegate.newValue) == "new value";
//                expect(view) == snapshot();
//            }
        }
      
    }
}

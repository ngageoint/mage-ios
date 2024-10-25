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

//class GeometryViewTests: KIFMageCoreDataTestCase {
//    
//    override func spec() {
//        
//        describe("GeometryView") {
//            var field: [String: Any]!
//                        
//            var geometryFieldView: GeometryView?
//            var view: UIView!
//            var controller: UIViewController!
//            var window: UIWindow!;
//            
//            beforeEach {
//                controller = UIViewController();
//                view = UIView(forAutoLayout: ());
//                view.autoSetDimension(.width, toSize: UIScreen.main.bounds.width);
//                view.backgroundColor = .systemBackground;
//                
//                controller?.view.addSubview(view);
//                
//                window = TestHelpers.getKeyWindowVisible();
//                window.rootViewController = controller;
//                
//                geometryFieldView?.removeFromSuperview();
//                geometryFieldView = nil;
//                for subview in view.subviews {
//                    subview.removeFromSuperview();
//                }
//                
//                field = [
//                    "title": "Field Title",
//                    "name": "field8",
//                    "type": "geometry",
//                    "id": 8
//                ];
//                
//                UserDefaults.standard.mapType = 0;
//                UserDefaults.standard.locationDisplay = .latlng;
////                Nimble_Snapshots.setNimbleTolerance(0.1);
////                Nimble_Snapshots.recordAllSnapshots();
//            }
//            
//            afterEach {
//                geometryFieldView?.removeFromSuperview();
//                geometryFieldView = nil;
//                for subview in view.subviews {
//                    subview.removeFromSuperview();
//                }
//            }
//            
//            it("edit mode reference image") {                
//                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
////                let mockMapDelegate = MockMapViewDelegate()
//                
////                let plainDelegate: PlainMapViewDelegate = PlainMapViewDelegate();
////                plainDelegate.mockMapViewDelegate = mockMapDelegate;
//                
//                geometryFieldView = GeometryView(field: field, value: point, accuracy: 100.487235, provider: "gps", mapEventDelegate: nil);//, mkmapDelegate: plainDelegate);
//                geometryFieldView!.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(geometryFieldView!)
//                geometryFieldView?.autoPinEdgesToSuperviewEdges();
//                
//                expect(geometryFieldView?.textField.text) == "40.0085, -105.2678 GPS ± 100.49m"
//                expect(geometryFieldView?.textField.label.text) == "Field Title"
//                
//            }
//            
//            it("no initial value") {
////                let mockMapDelegate: MockMapViewDelegate = MockMapViewDelegate()
//
//                geometryFieldView = GeometryView(field: field, mapEventDelegate: nil);
//                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
//
//                view.addSubview(geometryFieldView!)
//                geometryFieldView?.autoPinEdgesToSuperviewEdges();
//                
//                expect(geometryFieldView?.mapView.isHidden).to(beTrue());
//                expect(geometryFieldView?.textField.text) == "";
//                expect(geometryFieldView?.textField.label.text) == "Field Title"
//            }
//            
//            it("non edit mode reference image") {
//                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
//                geometryFieldView = GeometryView(field: field, editMode: false, value: point, accuracy: 100.487235, provider: "gps");
//                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(geometryFieldView!)
//                geometryFieldView?.autoPinEdgesToSuperviewEdges();
//                
//                expect(geometryFieldView?.latitudeLongitudeButton.currentTitle) == "40.0085, -105.2678";
//                expect(geometryFieldView?.latitudeLongitudeButton.isEnabled).to(beTrue());
//                expect(geometryFieldView?.accuracyLabel.text) == "GPS ± 100.49m";
//                expect(geometryFieldView?.fieldNameLabel.text) == "Field Title"
//                expect(geometryFieldView?.fieldNameLabel.superview).toNot(beNil());
//                
//                expect(geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
//                expect(geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
//            }
//            
//            it("non edit mode initial value set as a point") {
//                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
//                geometryFieldView = GeometryView(field: field, editMode: false, value: point, accuracy: 100.487235, provider: "gps");
//                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(geometryFieldView!)
//                geometryFieldView?.autoPinEdgesToSuperviewEdges();
//                
//                expect(geometryFieldView?.latitudeLongitudeButton.currentTitle) == "40.0085, -105.2678";
//                expect(geometryFieldView?.latitudeLongitudeButton.isEnabled).to(beTrue());
//                expect(geometryFieldView?.accuracyLabel.text) == "GPS ± 100.49m";
//                expect(geometryFieldView?.fieldNameLabel.text) == "Field Title"
//                expect(geometryFieldView?.fieldNameLabel.superview).toNot(beNil())
//                
//                expect(geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
//                expect(geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
//            }
//
//            it("initial value set as a point") {
//                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
//                geometryFieldView = GeometryView(field: field, value: point, accuracy: 100.487235, provider: "gps");
//                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(geometryFieldView!)
//                geometryFieldView?.autoPinEdgesToSuperviewEdges();
//
//                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
//                expect(geometryFieldView?.textField.text) == "40.0085, -105.2678 GPS ± 100.49m";
//                expect(geometryFieldView?.textField.label.text) == "Field Title"
//                
//                expect(geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
//                expect(geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
//            }
//            
//            it("initial value set as a point no title") {
//                field[FieldKey.title.key] = nil;
//                
//                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
//                geometryFieldView = GeometryView(field: field, value: point, accuracy: 100.487235, provider: "gps");
//                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(geometryFieldView!)
//                geometryFieldView?.autoPinEdgesToSuperviewEdges();
//                
//                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
//                expect(geometryFieldView?.textField.text) == "40.0085, -105.2678 GPS ± 100.49m";
//                expect(geometryFieldView?.textField.label.text) == ""
//                
//                expect(geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
//                expect(geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
//            }
//            
//            it("initial value set as a point MGRS") {
//                UserDefaults.standard.locationDisplay = .mgrs
//                
//                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
//                            
//                geometryFieldView = GeometryView(field: field, value: point, accuracy: 100.487235, provider: "gps");
//                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(geometryFieldView!)
//                geometryFieldView?.autoPinEdgesToSuperviewEdges();
//                
//                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
//                expect(geometryFieldView?.textField.text) == "13TDE7714328734 GPS ± 100.49m";
//                expect(geometryFieldView?.textField.label.text) == "Field Title"
//                
//                expect(geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
//                expect(geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
//            }
//            
//            it("initial value set wtih observation without geometry") {
//                let observation: Observation = ObservationBuilder.createBlankObservation()
//                
//                geometryFieldView = GeometryView(field: field, observation: observation);
//                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(geometryFieldView!)
//                geometryFieldView?.autoPinEdgesToSuperviewEdges();
//                
//                expect(geometryFieldView?.mapView.isHidden).to(beTrue());
//                expect(geometryFieldView?.textField.text) == "";
//                expect(geometryFieldView?.textField.label.text) == "Field Title"
//            }
//            
//            it("initial value set wtih observation") {
//                let observation: Observation = ObservationBuilder.createPointObservation();
//            
//                geometryFieldView = GeometryView(field: field, observation: observation);
//                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(geometryFieldView!)
//                geometryFieldView?.autoPinEdgesToSuperviewEdges();
//
//                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
//                expect(geometryFieldView?.textField.text) == "40.0085, -105.2678 ";
//                expect(geometryFieldView?.textField.label.text) == "Field Title"
//                
//                let point: SFPoint = observation.geometry!.centroid();
//                expect(geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
//                expect(geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
//                TestHelpers.printAllAccessibilityLabelsInWindows()
////                tester().waitForView(withAccessibilityLabel: "Observation Annotation \(observation.objectID.uriRepresentation())");
//            }
//            
//            it("initial value set wtih observation with accuracy") {
//                let observation: Observation = ObservationBuilder.createPointObservation();
//                ObservationBuilder.addObservationProperty(observation: observation, key: "provider", value: "gps")
//                ObservationBuilder.addObservationProperty(observation: observation, key: "accuracy", value: 100.487235)
//                     
//                geometryFieldView = GeometryView(field: field, observation: observation);
//                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(geometryFieldView!)
//                geometryFieldView?.autoPinEdgesToSuperviewEdges();
//    
//                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
//                expect(geometryFieldView?.textField.text) == "40.0085, -105.2678 GPS ± 100.49m";
//                expect(geometryFieldView?.textField.label.text) == "Field Title"
//                
//                let point: SFPoint = observation.geometry!.centroid();
//                expect(geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
//                expect(geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
////                tester().waitForView(withAccessibilityLabel: "Observation Annotation \(observation.objectID.uriRepresentation())");
//            }
//            
//            it("initial value set wtih observation with accuracy and provider") {
//                let observation: Observation = ObservationBuilder.createPointObservation();
//                ObservationBuilder.addObservationProperty(observation: observation, key: "accuracy", value: 100.487235)
//                ObservationBuilder.addObservationProperty(observation: observation, key: "provider", value: "gps")
//                     
//                geometryFieldView = GeometryView(field: field, observation: observation);
//                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(geometryFieldView!)
//                geometryFieldView?.autoPinEdgesToSuperviewEdges();
//
//                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
//                expect(geometryFieldView?.textField.text) == "40.0085, -105.2678 GPS ± 100.49m";
//                expect(geometryFieldView?.textField.label.text) == "Field Title"
//                
//                let point: SFPoint = observation.geometry!.centroid();
//                expect(geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
//                expect(geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
////                tester().waitForView(withAccessibilityLabel: "Observation Annotation \(observation.objectID.uriRepresentation())");
//            }
//            
//            it("initial value set wtih observation line") {
//                let observation: Observation = ObservationBuilder.createLineObservation();
//           
//                geometryFieldView = GeometryView(field: field, observation: observation);
//                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(geometryFieldView!)
//                geometryFieldView?.autoPinEdgesToSuperviewEdges();
//                
//                tester().waitForAnimationsToFinish();
//
//                let point: SFPoint = observation.geometry!.centroid();
//                expect(geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
//                expect(geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
//                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
//                expect(geometryFieldView?.textField.text) == "40.0085, -105.2666 ";
//                expect(geometryFieldView?.textField.label.text) == "Field Title"
//            }
//            
//            it("initial value set wtih observation polygon") {
//                let observation: Observation = ObservationBuilder.createPolygonObservation();
//                geometryFieldView = GeometryView(field: field, observation: observation);
//                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(geometryFieldView!)
//                geometryFieldView?.autoPinEdgesToSuperviewEdges();
//
//                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
//                expect(geometryFieldView?.textField.text) == "40.0093, -105.2666 ";
//                expect(geometryFieldView?.textField.label.text) == "Field Title"
//                
//                let point: SFPoint = observation.geometry!.centroid();
//                expect(geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
//                expect(geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
//            }
//            
//            it("set value later wtih observation with accuracy and provider") {
//                let observation: Observation = ObservationBuilder.createPointObservation();
//                ObservationBuilder.addObservationProperty(observation: observation, key: "accuracy", value: 100.487235)
//                ObservationBuilder.addObservationProperty(observation: observation, key: "provider", value: "gps")
//                                    
//                geometryFieldView = GeometryView(field: field, observation: nil);
//                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(geometryFieldView!)
//                geometryFieldView?.autoPinEdgesToSuperviewEdges();
//                                
//                geometryFieldView?.setObservation(observation: observation);
//                
//                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
//                expect(geometryFieldView?.textField.text) == "40.0085, -105.2678 GPS ± 100.49m";
//                expect(geometryFieldView?.textField.label.text) == "Field Title"
//                
//                let point: SFPoint = observation.geometry!.centroid();
//                expect(geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
//                expect(geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
////                tester().waitForView(withAccessibilityLabel: "Observation Annotation \(observation.objectID.uriRepresentation())");
//            }
//
//            it("set value later") {
//                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
//
//                geometryFieldView = GeometryView(field: field);
//                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
//
//                view.addSubview(geometryFieldView!)
//                geometryFieldView?.autoPinEdgesToSuperviewEdges();
//
//                geometryFieldView?.setValue(point);
//                
//                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
//                expect(geometryFieldView?.textField.text) == "40.0085, -105.2678 ";
//                expect(geometryFieldView?.textField.label.text) == "Field Title"
//                
//                expect(geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
//                expect(geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
//            }
//            
//            it("set value later with accuracy") {
//                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
//                geometryFieldView = GeometryView(field: field);
//                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
//                geometryFieldView?.setValue(point, accuracy: 100.487235, provider: "gps");
//                
//                view.addSubview(geometryFieldView!)
//                geometryFieldView?.autoPinEdgesToSuperviewEdges();
//                
//                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
//                expect(geometryFieldView?.textField.text) == "40.0085, -105.2678 GPS ± 100.49m";
//                expect(geometryFieldView?.textField.label.text) == "Field Title"
//                
//                expect(geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
//                expect(geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
//            }
//            
//            it("set value later with accuracy and no provider") {
//                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
//                
//                geometryFieldView = GeometryView(field: field);
//                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
//                geometryFieldView?.setValue(point, accuracy: 100.487235);
//                
//                view.addSubview(geometryFieldView!)
//                geometryFieldView?.autoPinEdgesToSuperviewEdges();
//
//                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
//                expect(geometryFieldView?.textField.text) == "40.0085, -105.2678 ";
//                expect(geometryFieldView?.textField.label.text) == "Field Title"
//                
//                expect(geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
//                expect(geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
//            }
//
//            it("set valid false") {
//                geometryFieldView = GeometryView(field: field);
//                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(geometryFieldView!)
//                geometryFieldView?.autoPinEdgesToSuperviewEdges();
//                geometryFieldView?.setValid(false);
//                
////                expect(view).to(haveValidSnapshot());
//
//                expect(geometryFieldView?.mapView.isHidden).to(beTrue());
//                expect(geometryFieldView?.textField.text) == "";
//                expect(geometryFieldView?.textField.label.text) == "Field Title"
//            }
//
//            it("set valid true after being invalid") {
//                                
//                geometryFieldView = GeometryView(field: field);
//                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(geometryFieldView!)
//                geometryFieldView?.autoPinEdgesToSuperviewEdges();
//                geometryFieldView?.setValid(false)
//                geometryFieldView?.setValid(true);
//                                
//                expect(geometryFieldView?.mapView.isHidden).to(beTrue());
//                expect(geometryFieldView?.textField.text) == "";
//                expect(geometryFieldView?.textField.label.text) == "Field Title"
//                expect(geometryFieldView?.textField.textColor) != MAGEScheme.scheme().colorScheme.errorColor;
//            }
//
//            it("required field is invalid if empty") {
//                field[FieldKey.required.key] = true;
//                
//                geometryFieldView = GeometryView(field: field);
//                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
//
//                expect(geometryFieldView?.isEmpty()) == true;
//                expect(geometryFieldView?.isValid(enforceRequired: true)) == false;
//                
//                expect(geometryFieldView?.mapView.isHidden).to(beTrue());
//                expect(geometryFieldView?.textField.text) == "";
//                expect(geometryFieldView?.textField.label.text) == "Field Title *"
//            }
//
//            it("required field is valid if not empty") {
//                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
//                field[FieldKey.required.key] = true;
//                
//                geometryFieldView = GeometryView(field: field, value: point);
//                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                expect(geometryFieldView?.isEmpty()) == false;
//                expect(geometryFieldView?.isValid(enforceRequired: true)) == true;
//                
//                expect(geometryFieldView?.mapView.isHidden).to(beFalse());
//                expect(geometryFieldView?.textField.text) == "40.0085, -105.2678 ";
//                expect(geometryFieldView?.textField.label.text) == "Field Title *"
//            }
//            
//            it("set value via input") {
//                let delegate = MockFieldDelegate();
//                
//                let nc = UINavigationController();
//                
//                window.rootViewController = nc;
//                controller.removeFromParent();
//                nc.pushViewController(controller, animated: false);
//                
//                geometryFieldView = GeometryView(field: field, delegate: delegate);
//                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(geometryFieldView!)
//                geometryFieldView?.autoPinEdgesToSuperviewEdges();
//                
//                tester().waitForView(withAccessibilityLabel: field[FieldKey.name.key] as? String);
//                geometryFieldView?.handleTap();
//                expect(delegate.launchFieldSelectionViewControllerCalled).to(beTrue());
//                expect(delegate.viewControllerToLaunch).to(beAnInstanceOf(GeometryEditViewController.self));
//                
//                nc.pushViewController(delegate.viewControllerToLaunch!, animated: false);
//                
//                tester().waitForView(withAccessibilityLabel: "Latitude Value")
//                tester().clearText(fromAndThenEnterText: "1.00000", intoViewWithAccessibilityLabel: "Latitude Value")
//                tester().clearText(fromAndThenEnterText: "1.00000", intoViewWithAccessibilityLabel: "Longitude Value")
//                viewTester().usingFirstResponder().view.resignFirstResponder();
//                tester().tapView(withAccessibilityLabel: "Apply");
//                
//                tester().waitForView(withAccessibilityLabel: field[FieldKey.name.key] as? String);
//                expect((viewTester().usingLabel("\(field[FieldKey.name.key] as? String ?? "") value")!.view as! MDCFilledTextField).text) == "1.0000, 1.0000 "
//                
//                expect(UIApplication.getTopViewController()).toNot(beAnInstanceOf(delegate.viewControllerToLaunch!.classForCoder));
//                
//                nc.popToRootViewController(animated: false);
//                window.rootViewController = controller;
//            }
//            
//            it("copy location") {
//                let point: SFPoint = SFPoint(x: -105.2678, andY: 40.0085);
//          
//                let mockActionsDelegate: MockObservationActionsDelegate = MockObservationActionsDelegate();
//                
//                geometryFieldView = GeometryView(field: field, editMode: false, value: point, accuracy: 100.487235, provider: "gps", observationActionsDelegate: mockActionsDelegate);
//                geometryFieldView?.applyTheme(withScheme: MAGEScheme.scheme());
//                
//                view.addSubview(geometryFieldView!)
//                geometryFieldView?.autoPinEdgesToSuperviewEdges();
//                
//                expect(geometryFieldView?.mapView.mapView?.region.center.latitude).toEventually(beCloseTo(point.y as! CLLocationDegrees, within: 0.005));
//                expect(geometryFieldView?.mapView.mapView?.region.center.longitude).toEventually(beCloseTo(point.x as! CLLocationDegrees, within: 0.005));
//                expect(geometryFieldView?.latitudeLongitudeButton.currentTitle) == "40.0085, -105.2678";
//                expect(geometryFieldView?.latitudeLongitudeButton.isEnabled).to(beTrue());
//                expect(geometryFieldView?.accuracyLabel.text) == "GPS ± 100.49m";
//                expect(geometryFieldView?.fieldNameLabel.text) == "Field Title"
//                
//                tester().tapView(withAccessibilityLabel: "location button");
//                tester().waitForView(withAccessibilityLabel: "Location 40.0085, -105.2678 copied to clipboard")
//            }
//        }
//    }
//}

//
//  CoordinateFieldTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 1/20/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble

@testable import MAGE

class CoordinateFieldTests: KIFSpec {
    
    override func spec() {
        
        describe("CoordinateFieldTests") {
            var view: UIView!
            var controller: UIViewController!
            var window: UIWindow!;
            
            beforeEach {
                controller = UIViewController();
                window = TestHelpers.getKeyWindowVisible();
                window.rootViewController = controller;
                if (view != nil) {
                    for subview in view.subviews {
                        subview.removeFromSuperview();
                    }
                }
                view = UIView(forAutoLayout: ());
                view.backgroundColor = .systemBackground;
                controller.view.addSubview(view);
                view.autoPinEdgesToSuperviewEdges();
            }
            
            afterEach {
                for subview in view.subviews {
                    subview.removeFromSuperview();
                }
                controller.dismiss(animated: false, completion: nil);
                window.rootViewController = nil;
                controller = nil;
                view = nil;
            }
            
            it("should load the view") {
                let field = CoordinateField(latitude: true, text: "111122N", label: "Coordinate", delegate: nil, scheme: MAGEScheme.scheme())
                field.placeholder = "Placeholder"
                view.addSubview(field);
                field.autoPinEdge(toSuperviewEdge: .left);
                field.autoPinEdge(toSuperviewEdge: .right);
                field.autoAlignAxis(toSuperviewAxis: .horizontal);
                expect(field.isHidden).to(beFalse());
                expect(field.textField.text).to(equal("11° 11' 22\" N"))
                expect(field.textField.label.text).to(equal("Coordinate"))
                expect(field.label).to(equal("Coordinate"))
                expect(field.textField.accessibilityLabel).to(equal("Coordinate"))
                expect(field.textField.placeholder).to(equal("Placeholder"))
                expect(field.placeholder).to(equal("Placeholder"))
                expect(field.isEditing).to(beFalse())
            }
            
            it("should set the text later") {
                let field = CoordinateField(latitude: true, text: nil, label: "Coordinate", delegate: nil, scheme: MAGEScheme.scheme())
                view.addSubview(field);
                field.autoPinEdge(toSuperviewEdge: .left);
                field.autoPinEdge(toSuperviewEdge: .right);
                field.autoAlignAxis(toSuperviewAxis: .horizontal);
                expect(field.isHidden).to(beFalse());
                expect(field.textField.text).to(equal(""))
                expect(field.text).to(equal(""))
                field.text = "111122N"
                expect(field.textField.text).to(equal("11° 11' 22\" N"))
                expect(field.text).to(equal("11° 11' 22\" N"))
                expect(field.textField.label.text).to(equal("Coordinate"))
                expect(field.textField.accessibilityLabel).to(equal("Coordinate"))
            }
            
            it("should enable and disable the field") {
                let field = CoordinateField(latitude: true, text: nil, label: "Coordinate", delegate: nil, scheme: MAGEScheme.scheme())
                view.addSubview(field);
                field.autoPinEdge(toSuperviewEdge: .left);
                field.autoPinEdge(toSuperviewEdge: .right);
                field.autoAlignAxis(toSuperviewAxis: .horizontal);
                expect(field.isHidden).to(beFalse());
                expect(field.textField.text).to(equal(""))
                expect(field.text).to(equal(""))
                expect(field.isEnabled).to(beTrue())
                expect(field.textField.isEnabled).to(beTrue())
                
                field.isEnabled = false
                
                expect(field.isEnabled).to(beFalse())
                expect(field.textField.isEnabled).to(beFalse())
            }
            
            it("should edit the field and notify the delegate") {
                class MockCoordinateFieldDelegate: NSObject, CoordinateFieldDelegate {
                    var fieldChangedCalled = false;
                    var changedValue: CLLocationDegrees?
                    var changedField: CoordinateField?
                    func fieldValueChanged(coordinate: CLLocationDegrees, field: CoordinateField) {
                        fieldChangedCalled = true
                        changedValue = coordinate
                        changedField = field
                    }
                }
                
                let delegate = MockCoordinateFieldDelegate()
                let field = CoordinateField(latitude: true, text: nil, label: "Coordinate", delegate: delegate, scheme: MAGEScheme.scheme())
                view.addSubview(field);
                field.autoPinEdge(toSuperviewEdge: .left);
                field.autoPinEdge(toSuperviewEdge: .right);
                field.autoAlignAxis(toSuperviewAxis: .horizontal);
                expect(field.isHidden).to(beFalse());
                expect(field.textField.text).to(equal(""))
                expect(field.text).to(equal(""))
                tester().waitForView(withAccessibilityLabel: "Coordinate")
                tester().tapView(withAccessibilityLabel: "Coordinate")
                expect(field.isEditing).to(beTrue())
                tester().enterText(intoCurrentFirstResponder: "113000N")
                expect(field.textField.text).to(equal("11° 30' 00\" N"))
                expect(field.text).to(equal("11° 30' 00\" N"))
                expect(field.textField.label.text).to(equal("Coordinate"))
                expect(field.textField.accessibilityLabel).to(equal("Coordinate"))
                field.resignFirstResponder()
                expect(field.isEditing).to(beFalse())
                expect(delegate.fieldChangedCalled).to(beTrue())
                expect(delegate.changedValue).to(equal(11.5))
            }
            
            it("should not start clearing text if multiple directions are entered") {
                class MockCoordinateFieldDelegate: NSObject, CoordinateFieldDelegate {
                    var fieldChangedCalled = false;
                    var changedValue: CLLocationDegrees?
                    var changedField: CoordinateField?
                    func fieldValueChanged(coordinate: CLLocationDegrees, field: CoordinateField) {
                        fieldChangedCalled = true
                        changedValue = coordinate
                        changedField = field
                    }
                }
                
                let delegate = MockCoordinateFieldDelegate()
                let field = CoordinateField(latitude: true, text: nil, label: "Coordinate", delegate: delegate, scheme: MAGEScheme.scheme())
                view.addSubview(field);
                field.autoPinEdge(toSuperviewEdge: .left);
                field.autoPinEdge(toSuperviewEdge: .right);
                field.autoAlignAxis(toSuperviewAxis: .horizontal);
                expect(field.isHidden).to(beFalse());
                expect(field.textField.text).to(equal(""))
                expect(field.text).to(equal(""))
                tester().waitForView(withAccessibilityLabel: "Coordinate")
                tester().tapView(withAccessibilityLabel: "Coordinate")
                expect(field.isEditing).to(beTrue())
                tester().enterText(intoCurrentFirstResponder: "113000NNNN")
                expect(field.textField.text).to(equal("11° 30' 00\" N"))
                expect(field.text).to(equal("11° 30' 00\" N"))
                expect(field.textField.label.text).to(equal("Coordinate"))
                expect(field.textField.accessibilityLabel).to(equal("Coordinate"))
                field.resignFirstResponder()
                expect(field.isEditing).to(beFalse())
                expect(delegate.fieldChangedCalled).to(beTrue())
                expect(delegate.changedValue).to(equal(11.5))
            }
            
            it("should paste into the field") {
                let field = CoordinateField(latitude: true, text: "111122N", label: "Coordinate", delegate: nil, scheme: MAGEScheme.scheme())
                view.addSubview(field);
                field.autoPinEdge(toSuperviewEdge: .left);
                field.autoPinEdge(toSuperviewEdge: .right);
                field.autoAlignAxis(toSuperviewAxis: .horizontal);
                expect(field.isHidden).to(beFalse());
                expect(field.textField.text).to(equal("11° 11' 22\" N"))
                expect(field.text).to(equal("11° 11' 22\" N"))
                tester().waitForView(withAccessibilityLabel: "Coordinate")
                tester().tapView(withAccessibilityLabel: "Coordinate")
                expect(field.isEditing).to(beTrue())
                tester().clearTextFromFirstResponder()
                expect(field.textField(field.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: "112233N")).to(beFalse())
                expect(field.textField.text).to(equal("11° 22' 33\" N"))
                expect(field.text).to(equal("11° 22' 33\" N"))
                expect(field.textField.label.text).to(equal("Coordinate"))
                expect(field.textField.accessibilityLabel).to(equal("Coordinate"))
                field.resignFirstResponder()
                expect(field.isEditing).to(beFalse())
            }
            
            it("should paste into the field something with fractional seconds") {
                let field = CoordinateField(latitude: true, text: "111122.25N", label: "Coordinate", delegate: nil, scheme: MAGEScheme.scheme())
                view.addSubview(field);
                field.autoPinEdge(toSuperviewEdge: .left);
                field.autoPinEdge(toSuperviewEdge: .right);
                field.autoAlignAxis(toSuperviewAxis: .horizontal);
                expect(field.isHidden).to(beFalse());
                expect(field.textField.text).to(equal("11° 11' 22\" N"))
                expect(field.text).to(equal("11° 11' 22\" N"))
                tester().waitForView(withAccessibilityLabel: "Coordinate")
                tester().tapView(withAccessibilityLabel: "Coordinate")
                expect(field.isEditing).to(beTrue())
                tester().clearTextFromFirstResponder()
                expect(field.textField(field.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: "112233.99N")).to(beFalse())
                expect(field.textField.text).to(equal("11° 22' 34\" N"))
                expect(field.text).to(equal("11° 22' 34\" N"))
                expect(field.textField.label.text).to(equal("Coordinate"))
                expect(field.textField.accessibilityLabel).to(equal("Coordinate"))
                field.resignFirstResponder()
                expect(field.isEditing).to(beFalse())
            }
            
            it("should edit the field with negative") {
                let field = CoordinateField(latitude: true, text: "11N", label: "Coordinate", delegate: nil, scheme: MAGEScheme.scheme())
                view.addSubview(field);
                field.autoPinEdge(toSuperviewEdge: .left);
                field.autoPinEdge(toSuperviewEdge: .right);
                field.autoAlignAxis(toSuperviewAxis: .horizontal);
                expect(field.isHidden).to(beFalse());
                tester().waitForView(withAccessibilityLabel: "Coordinate")
                tester().tapView(withAccessibilityLabel: "Coordinate")
                expect(field.isEditing).to(beTrue())
                tester().clearTextFromFirstResponder()
                expect(field.textField(field.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: "-11.5")).to(beFalse())
                expect(field.textField.text).to(equal("11° 30' 00\" S"))
                expect(field.text).to(equal("11° 30' 00\" S"))
                expect(field.textField.label.text).to(equal("Coordinate"))
                expect(field.textField.accessibilityLabel).to(equal("Coordinate"))
                field.resignFirstResponder()
                expect(field.isEditing).to(beFalse())
            }
            
            it("should edit the field and be invalid") {
                class MockCoordinateFieldDelegate: NSObject, CoordinateFieldDelegate {
                    var fieldChangedCalled = false;
                    var changedValue: CLLocationDegrees?
                    var changedField: CoordinateField?
                    func fieldValueChanged(coordinate: CLLocationDegrees, field: CoordinateField) {
                        fieldChangedCalled = true
                        changedValue = coordinate
                        changedField = field
                    }
                }
                
                let delegate = MockCoordinateFieldDelegate()
                let field = CoordinateField(latitude: true, text: "11N", label: "Coordinate", delegate: delegate, scheme: MAGEScheme.scheme())
                view.addSubview(field);
                field.autoPinEdge(toSuperviewEdge: .left);
                field.autoPinEdge(toSuperviewEdge: .right);
                field.autoAlignAxis(toSuperviewAxis: .horizontal);
                expect(field.isHidden).to(beFalse());
                tester().waitForView(withAccessibilityLabel: "Coordinate")
                tester().tapView(withAccessibilityLabel: "Coordinate")
                expect(field.isEditing).to(beTrue())
                tester().clearTextFromFirstResponder()
                expect(field.textField(field.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: "N")).to(beFalse())
                expect(field.textField.text).to(equal("N"))
                expect(field.text).to(equal("N"))
                expect(field.textField.label.text).to(equal("Coordinate"))
                expect(field.textField.accessibilityLabel).to(equal("Coordinate"))
                field.resignFirstResponder()
                expect(field.isEditing).to(beFalse())
                expect(delegate.fieldChangedCalled).to(beTrue())
                expect(delegate.changedValue?.isNaN).to(beTrue())
            }
            
            it("should populate the field properly for pasted in text which can be split") {
                class MockCoordinateFieldDelegate: NSObject, CoordinateFieldDelegate {
                    var fieldChangedCalled = false;
                    var changedValue: CLLocationDegrees?
                    var changedField: CoordinateField?
                    func fieldValueChanged(coordinate: CLLocationDegrees, field: CoordinateField) {
                        fieldChangedCalled = true
                        changedValue = coordinate
                        changedField = field
                    }
                }
                
                let delegate = MockCoordinateFieldDelegate()
                let field = CoordinateField(latitude: true, text: "11N", label: "Coordinate", delegate: delegate, scheme: MAGEScheme.scheme())
                view.addSubview(field);
                field.autoPinEdge(toSuperviewEdge: .left);
                field.autoPinEdge(toSuperviewEdge: .right);
                field.autoAlignAxis(toSuperviewAxis: .horizontal);
                expect(field.isHidden).to(beFalse());
                tester().waitForView(withAccessibilityLabel: "Coordinate")
                tester().tapView(withAccessibilityLabel: "Coordinate")
                expect(field.isEditing).to(beTrue())
                tester().clearTextFromFirstResponder()
                expect(field.textField(field.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: "N 11 ° 22'30 \"- W 15 ° 15'45")).to(beFalse())
                expect(field.textField.text).to(equal("11° 22' 30\" N"))
                expect(field.text).to(equal("11° 22' 30\" N"))
                expect(field.textField.label.text).to(equal("Coordinate"))
                expect(field.textField.accessibilityLabel).to(equal("Coordinate"))
                field.resignFirstResponder()
                expect(field.isEditing).to(beFalse())
                expect(delegate.fieldChangedCalled).to(beTrue())
                expect(delegate.changedValue).to(equal(11.375))
            }
            
            it("should populate the longitude field properly for pasted in text which can be split") {
                class MockCoordinateFieldDelegate: NSObject, CoordinateFieldDelegate {
                    var fieldChangedCalled = false;
                    var changedValue: CLLocationDegrees?
                    var changedField: CoordinateField?
                    func fieldValueChanged(coordinate: CLLocationDegrees, field: CoordinateField) {
                        fieldChangedCalled = true
                        changedValue = coordinate
                        changedField = field
                    }
                }
                
                let delegate = MockCoordinateFieldDelegate()
                let field = CoordinateField(latitude: true, text: nil, label: "Coordinate Latitude", delegate: delegate, scheme: MAGEScheme.scheme())
                view.addSubview(field);
                field.autoPinEdges(toSuperviewMarginsExcludingEdge: .bottom)
                
                let delegate2 = MockCoordinateFieldDelegate()
                let longitude = CoordinateField(latitude: false, text: nil, label: "Coordinate Longitude", delegate: delegate2, scheme: MAGEScheme.scheme())
                view.addSubview(longitude);
                longitude.autoPinEdges(toSuperviewMarginsExcludingEdge: .top)
                longitude.autoPinEdge(.top, to: .bottom, of: field)
                field.linkedLongitudeField = longitude
                
                expect(field.isHidden).to(beFalse());
                tester().waitForView(withAccessibilityLabel: "Coordinate Latitude")
                tester().tapView(withAccessibilityLabel: "Coordinate Latitude")
                expect(field.isEditing).to(beTrue())
                tester().clearTextFromFirstResponder()
                expect(field.textField(field.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: "N 11 ° 22'30 \"- W 15 ° 15'45")).to(beFalse())
                expect(field.textField.text).to(equal("11° 22' 30\" N"))
                expect(field.text).to(equal("11° 22' 30\" N"))
                expect(field.textField.label.text).to(equal("Coordinate Latitude"))
                expect(field.textField.accessibilityLabel).to(equal("Coordinate Latitude"))
                field.resignFirstResponder()
                expect(field.isEditing).to(beFalse())
                expect(delegate.fieldChangedCalled).to(beTrue())
                expect(delegate.changedValue).to(equal(11.375))
                
                expect(longitude.textField.text).to(equal("15° 15' 45\" W"))
                expect(longitude.text).to(equal("15° 15' 45\" W"))
                expect(longitude.textField.label.text).to(equal("Coordinate Longitude"))
                expect(longitude.textField.accessibilityLabel).to(equal("Coordinate Longitude"))
                
                expect(delegate2.fieldChangedCalled).to(beTrue())
                expect(delegate2.changedValue).to(equal(-15.2625))
            }
            
            it("should populate the latitude field properly for pasted in text which can be split") {
                class MockCoordinateFieldDelegate: NSObject, CoordinateFieldDelegate {
                    var fieldChangedCalled = false;
                    var changedValue: CLLocationDegrees?
                    var changedField: CoordinateField?
                    func fieldValueChanged(coordinate: CLLocationDegrees, field: CoordinateField) {
                        fieldChangedCalled = true
                        changedValue = coordinate
                        changedField = field
                    }
                }
                
                let delegate = MockCoordinateFieldDelegate()
                let field = CoordinateField(latitude: true, text: nil, label: "Coordinate Latitude", delegate: delegate, scheme: MAGEScheme.scheme())
                view.addSubview(field);
                field.autoPinEdges(toSuperviewMarginsExcludingEdge: .bottom)
                
                let delegate2 = MockCoordinateFieldDelegate()
                let longitude = CoordinateField(latitude: false, text: nil, label: "Coordinate Longitude", delegate: delegate2, scheme: MAGEScheme.scheme())
                view.addSubview(longitude);
                longitude.autoPinEdges(toSuperviewMarginsExcludingEdge: .top)
                longitude.autoPinEdge(.top, to: .bottom, of: field)
                field.linkedLongitudeField = longitude
                longitude.linkedLatitudeField = field
                
                expect(field.isHidden).to(beFalse());
                tester().waitForView(withAccessibilityLabel: "Coordinate Longitude")
                tester().tapView(withAccessibilityLabel: "Coordinate Longitude")
                expect(longitude.isEditing).to(beTrue())
                tester().clearTextFromFirstResponder()
                expect(longitude.textField(longitude.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: "N 11 ° 22'30 \"- W 15 ° 15'45")).to(beFalse())
                expect(field.textField.text).to(equal("11° 22' 30\" N"))
                expect(field.text).to(equal("11° 22' 30\" N"))
                expect(field.textField.label.text).to(equal("Coordinate Latitude"))
                expect(field.textField.accessibilityLabel).to(equal("Coordinate Latitude"))
                field.resignFirstResponder()
                expect(field.isEditing).to(beFalse())
                expect(delegate.fieldChangedCalled).to(beTrue())
                expect(delegate.changedValue).to(equal(11.375))
                
                expect(longitude.textField.text).to(equal("15° 15' 45\" W"))
                expect(longitude.text).to(equal("15° 15' 45\" W"))
                expect(longitude.textField.label.text).to(equal("Coordinate Longitude"))
                expect(longitude.textField.accessibilityLabel).to(equal("Coordinate Longitude"))
                
                expect(delegate2.fieldChangedCalled).to(beTrue())
                expect(delegate2.changedValue).to(equal(-15.2625))
            }
            
            it("should populate the fields properly for pasted in longitude field in decimal degree text which can be split") {
                class MockCoordinateFieldDelegate: NSObject, CoordinateFieldDelegate {
                    var fieldChangedCalled = false;
                    var changedValue: CLLocationDegrees?
                    var changedField: CoordinateField?
                    func fieldValueChanged(coordinate: CLLocationDegrees, field: CoordinateField) {
                        fieldChangedCalled = true
                        changedValue = coordinate
                        changedField = field
                    }
                }
                
                let delegate = MockCoordinateFieldDelegate()
                let field = CoordinateField(latitude: true, text: nil, label: "Coordinate Latitude", delegate: delegate, scheme: MAGEScheme.scheme())
                view.addSubview(field);
                field.autoPinEdges(toSuperviewMarginsExcludingEdge: .bottom)
                
                let delegate2 = MockCoordinateFieldDelegate()
                let longitude = CoordinateField(latitude: false, text: nil, label: "Coordinate Longitude", delegate: delegate2, scheme: MAGEScheme.scheme())
                view.addSubview(longitude);
                longitude.autoPinEdges(toSuperviewMarginsExcludingEdge: .top)
                longitude.autoPinEdge(.top, to: .bottom, of: field)
                field.linkedLongitudeField = longitude
                longitude.linkedLatitudeField = field
                
                expect(field.isHidden).to(beFalse());
                tester().waitForView(withAccessibilityLabel: "Coordinate Longitude")
                tester().tapView(withAccessibilityLabel: "Coordinate Longitude")
                expect(longitude.isEditing).to(beTrue())
                tester().clearTextFromFirstResponder()
                expect(longitude.textField(longitude.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: "11.375 -15.2625")).to(beFalse())
                expect(field.textField.text).to(equal("11° 22' 30\" N"))
                expect(field.text).to(equal("11° 22' 30\" N"))
                expect(field.textField.label.text).to(equal("Coordinate Latitude"))
                expect(field.textField.accessibilityLabel).to(equal("Coordinate Latitude"))
                field.resignFirstResponder()
                expect(field.isEditing).to(beFalse())
                expect(delegate.fieldChangedCalled).to(beTrue())
                expect(delegate.changedValue).to(equal(11.375))
                
                expect(longitude.textField.text).to(equal("15° 15' 45\" W"))
                expect(longitude.text).to(equal("15° 15' 45\" W"))
                expect(longitude.textField.label.text).to(equal("Coordinate Longitude"))
                expect(longitude.textField.accessibilityLabel).to(equal("Coordinate Longitude"))
                
                expect(delegate2.fieldChangedCalled).to(beTrue())
                expect(delegate2.changedValue).to(equal(-15.2625))
            }
            
            it("should populate the fields properly for pasted in latitude field in decimal degree text which can be split") {
                class MockCoordinateFieldDelegate: NSObject, CoordinateFieldDelegate {
                    var fieldChangedCalled = false;
                    var changedValue: CLLocationDegrees?
                    var changedField: CoordinateField?
                    func fieldValueChanged(coordinate: CLLocationDegrees, field: CoordinateField) {
                        fieldChangedCalled = true
                        changedValue = coordinate
                        changedField = field
                    }
                }
                
                let delegate = MockCoordinateFieldDelegate()
                let field = CoordinateField(latitude: true, text: nil, label: "Coordinate Latitude", delegate: delegate, scheme: MAGEScheme.scheme())
                view.addSubview(field);
                field.autoPinEdges(toSuperviewMarginsExcludingEdge: .bottom)
                
                let delegate2 = MockCoordinateFieldDelegate()
                let longitude = CoordinateField(latitude: false, text: nil, label: "Coordinate Longitude", delegate: delegate2, scheme: MAGEScheme.scheme())
                view.addSubview(longitude);
                longitude.autoPinEdges(toSuperviewMarginsExcludingEdge: .top)
                longitude.autoPinEdge(.top, to: .bottom, of: field)
                field.linkedLongitudeField = longitude
                longitude.linkedLatitudeField = field
                
                expect(field.isHidden).to(beFalse());
                tester().waitForView(withAccessibilityLabel: "Coordinate Longitude")
                tester().tapView(withAccessibilityLabel: "Coordinate Longitude")
                expect(longitude.isEditing).to(beTrue())
                tester().clearTextFromFirstResponder()
                expect(field.textField(field.textField, shouldChangeCharactersIn: NSRange(location: 0, length: 0), replacementString: "11.375 -15.2625")).to(beFalse())
                expect(field.textField.text).to(equal("11° 22' 30\" N"))
                expect(field.text).to(equal("11° 22' 30\" N"))
                expect(field.textField.label.text).to(equal("Coordinate Latitude"))
                expect(field.textField.accessibilityLabel).to(equal("Coordinate Latitude"))
                field.resignFirstResponder()
                expect(field.isEditing).to(beFalse())
                expect(delegate.fieldChangedCalled).to(beTrue())
                expect(delegate.changedValue).to(equal(11.375))
                
                expect(longitude.textField.text).to(equal("15° 15' 45\" W"))
                expect(longitude.text).to(equal("15° 15' 45\" W"))
                expect(longitude.textField.label.text).to(equal("Coordinate Longitude"))
                expect(longitude.textField.accessibilityLabel).to(equal("Coordinate Longitude"))
                
                expect(delegate2.fieldChangedCalled).to(beTrue())
                expect(delegate2.changedValue).to(equal(-15.2625))
            }
        }
    }
}

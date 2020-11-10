//
//  EditCheckboxFieldView.swift
//  MAGETests
//
//  Created by Daniel Barela on 5/28/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Nimble_Snapshots

@testable import MAGE

class EditCheckboxFieldViewTests: KIFSpec {
    
    override func spec() {
        
        describe("EditCheckboxFieldView Single selection") {
            let recordSnapshots = false;
            var completeTest = false;
            
            var controller: UIViewController!
            var window: UIWindow!;
            
            var checkboxFieldView: EditCheckboxFieldView!
            var view: UIView!
            var field: [String: Any]!
            
            func maybeRecordSnapshot(_ view: UIView, recordThisSnapshot: Bool = false, doneClosure: (() -> Void)?) {
                if (recordSnapshots || recordThisSnapshot) {
                    DispatchQueue.global(qos: .userInitiated).async {
                        Thread.sleep(forTimeInterval: 0.1);
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
                completeTest = false;
                window = UIWindow(forAutoLayout: ());
                window.autoSetDimension(.width, toSize: 300);
                
                controller = UIViewController();
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
                window.makeKeyAndVisible();
                
                window.rootViewController = controller;
                
                field = [
                    "title": "Field Title",
                    "name": "field8",
                    "id": 8
                ];
            }
            
            it("no initial value") {
                checkboxFieldView = EditCheckboxFieldView(field: field);
                
                view.addSubview(checkboxFieldView)
                checkboxFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("initial value true") {
                checkboxFieldView = EditCheckboxFieldView(field: field, value: true);
                
                view.addSubview(checkboxFieldView)
                checkboxFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("initial value false") {
                checkboxFieldView = EditCheckboxFieldView(field: field, value: false);
                
                view.addSubview(checkboxFieldView)
                checkboxFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("set value later") {
                checkboxFieldView = EditCheckboxFieldView(field: field);
                
                view.addSubview(checkboxFieldView)
                checkboxFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                checkboxFieldView.setValue(true);
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("set value simulated touch") {
                checkboxFieldView = EditCheckboxFieldView(field: field);
                
                view.addSubview(checkboxFieldView)
                checkboxFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                
                tester().waitForView(withAccessibilityLabel: field["name"] as? String);
                tester().setOn(true, forSwitchWithAccessibilityLabel: field["name"] as? String);
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("required") {
                field["required"] = true;
                checkboxFieldView = EditCheckboxFieldView(field: field);
                
                view.addSubview(checkboxFieldView)
                checkboxFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                checkboxFieldView.setValue(true);
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("set valid false") {
                checkboxFieldView = EditCheckboxFieldView(field: field);
                
                view.addSubview(checkboxFieldView)
                checkboxFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                
                checkboxFieldView.setValid(false);
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("set valid true after being invalid") {
                checkboxFieldView = EditCheckboxFieldView(field: field);
                
                view.addSubview(checkboxFieldView)
                checkboxFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                
                checkboxFieldView.setValid(false);
                checkboxFieldView.setValid(true);
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("required field is invalid if false") {
                field[FieldKey.required.key] = true;
                
                checkboxFieldView = EditCheckboxFieldView(field: field);
                
                view.addSubview(checkboxFieldView)
                checkboxFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                
                expect(checkboxFieldView.isEmpty()) == true;
                expect(checkboxFieldView.isValid(enforceRequired: true)) == false;
                checkboxFieldView.setValid(checkboxFieldView.isValid());
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("required field is valid if true") {
                field[FieldKey.required.key] = true;
                
                checkboxFieldView = EditCheckboxFieldView(field: field);
                
                view.addSubview(checkboxFieldView)
                checkboxFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                
                checkboxFieldView.setValue(true);
                expect(checkboxFieldView.isEmpty()) == false;
                expect(checkboxFieldView.isValid(enforceRequired: true)) == true;
                checkboxFieldView.setValid(checkboxFieldView.isValid());
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("test delegate false value") {
                let delegate = MockFieldDelegate();
                checkboxFieldView = EditCheckboxFieldView(field: field, delegate: delegate);

                view.addSubview(checkboxFieldView)
                checkboxFieldView.autoPinEdgesToSuperviewEdges();

                controller.view.addSubview(view);
                checkboxFieldView.switchValueChanged(theSwitch: checkboxFieldView.checkboxSwitch);
                expect(delegate.fieldChangedCalled) == true;
                expect(delegate.newValue as? Bool) == false;
            }
            
            it("test delegate true value") {
                let delegate = MockFieldDelegate();
                checkboxFieldView = EditCheckboxFieldView(field: field, delegate: delegate);
                
                view.addSubview(checkboxFieldView)
                checkboxFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                checkboxFieldView.setValue(true);
                checkboxFieldView.switchValueChanged(theSwitch: checkboxFieldView.checkboxSwitch);
                expect(delegate.fieldChangedCalled) == true;
                expect(delegate.newValue as? Bool) == true;
            }
        }
    }
}
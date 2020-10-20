//
//  EditDropdownFieldViewTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 5/27/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Nimble_Snapshots

@testable import MAGE

class EditDropdownFieldViewTests: QuickSpec {
    
    override func spec() {
        
        describe("EditDropdownFieldView Single selection") {
            let recordSnapshots = false;
            var completeTest = false;
            
            var controller: UIViewController!
            var window: UIWindow!;
            
            var dropdownFieldView: EditDropdownFieldView!
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
                
                field = ["title": "Field Title"];
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
            }
            
            it("no initial value") {
                dropdownFieldView = EditDropdownFieldView(field: field);
                
                view.addSubview(dropdownFieldView)
                dropdownFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                expect(dropdownFieldView.isEmpty()) == true;
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("initial value set") {
                dropdownFieldView = EditDropdownFieldView(field: field, value: "Hello");
                
                view.addSubview(dropdownFieldView)
                dropdownFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                expect(dropdownFieldView.isEmpty()) == false;

                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("initial value set with multiple values") {
                dropdownFieldView = EditDropdownFieldView(field: field, value: ["Hello", "hi"]);
                
                view.addSubview(dropdownFieldView)
                dropdownFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                expect(dropdownFieldView.isEmpty()) == false;

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
                dropdownFieldView = EditDropdownFieldView(field: field);
                
                view.addSubview(dropdownFieldView)
                dropdownFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                expect(dropdownFieldView.isEmpty()) == true;
                dropdownFieldView.setValue(["green", "purple"]);
                expect(dropdownFieldView.isEmpty()) == false;
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("required field should show status") {
                field[FieldKey.required.key] = true;
                dropdownFieldView = EditDropdownFieldView(field: field);
                
                view.addSubview(dropdownFieldView)
                dropdownFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                expect(dropdownFieldView.isEmpty()) == true;
                dropdownFieldView.setValid(dropdownFieldView.isValid());
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("required field should show status after value has been added") {
                field[FieldKey.required.key] = true;
                dropdownFieldView = EditDropdownFieldView(field: field);
                
                view.addSubview(dropdownFieldView)
                dropdownFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                expect(dropdownFieldView.isEmpty()) == true;
                dropdownFieldView.setValid(dropdownFieldView.isValid());
                dropdownFieldView.setValue("purple");
                expect(dropdownFieldView.getValue() as? [String]?) == ["purple"];
                expect(dropdownFieldView.isEmpty()) == false;
                dropdownFieldView.setValid(dropdownFieldView.isValid());
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("handle tap") {
                let delegate = MockFieldDelegate();
                dropdownFieldView = EditDropdownFieldView(field: field, delegate: delegate);
                
                view.addSubview(dropdownFieldView)
                dropdownFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                dropdownFieldView.handleTap(sender: UITapGestureRecognizer());
                expect(delegate.fieldSelected) == true;
            }
        }
    }
}

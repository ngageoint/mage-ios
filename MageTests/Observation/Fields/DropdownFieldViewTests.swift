//
//  DropdownFieldViewTests.swift
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

class DropdownFieldViewTests: KIFSpec {
    
    override func spec() {
        describe("DropdownFieldView") {
            let recordSnapshots = false;
            var completeTest = false;
            
            var controller: UIViewController!
            var window: UIWindow!;
            
            var dropdownFieldView: DropdownFieldView!
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
                window.backgroundColor = .systemBackground;
                
                controller = UIViewController();
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
                window.makeKeyAndVisible();
                
                field = [
                    "title": "Field Title",
                    "name": "field8",
                    "type": "dropdown",
                    "id": 8
                ];
                
                window.rootViewController = controller;
            }
            
            afterEach {
                controller.dismiss(animated: false, completion: nil);
                window.rootViewController = nil;
                controller = nil;
            }
            
            it("non edit mode") {
                dropdownFieldView = DropdownFieldView(field: field, editMode: false, value: "The Value");
                dropdownFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(dropdownFieldView)
                dropdownFieldView.autoPinEdgesToSuperviewEdges();
                
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
            
            it("no initial value") {
                dropdownFieldView = DropdownFieldView(field: field);
                dropdownFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
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
                dropdownFieldView = DropdownFieldView(field: field, value: "Hello");
                dropdownFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
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
            
            it("set value via input") {
                let delegate = MockFieldDelegate();
                dropdownFieldView = DropdownFieldView(field: field, delegate: delegate);
                dropdownFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(dropdownFieldView)
                dropdownFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view = view;
                tester().waitForView(withAccessibilityLabel: field[FieldKey.name.key] as? String);
                dropdownFieldView.handleTap();
                expect(delegate.launchFieldSelectionViewControllerCalled).to(beTrue());
                expect(delegate.viewControllerToLaunch).to(beAnInstanceOf(SelectEditViewController.self));
            }
            
            it("required field should show status") {
                field[FieldKey.required.key] = true;
                dropdownFieldView = DropdownFieldView(field: field);
                dropdownFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
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
                dropdownFieldView = DropdownFieldView(field: field);
                dropdownFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(dropdownFieldView)
                dropdownFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                expect(dropdownFieldView.isEmpty()) == true;
                dropdownFieldView.setValid(dropdownFieldView.isValid());
                dropdownFieldView.setValue("purple");
                expect(dropdownFieldView.getValue()) == "purple";
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
        }
    }
}

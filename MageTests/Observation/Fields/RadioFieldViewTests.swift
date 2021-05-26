//
//  RadioFieldViewTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 5/26/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Nimble_Snapshots

@testable import MAGE

class RadioFieldViewTests: KIFSpec {
    
    override func spec() {
        fdescribe("RadioFieldView") {
            let recordSnapshots = false;
            var completeTest = false;
            
            var controller: UIViewController!
            var window: UIWindow!;
            
            var radioFieldView: RadioFieldView!
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
                    "type": "radio",
                    "id": 8,
                    "choices": [
                        [
                            "value": 0,
                            "id": 0,
                            "title": "Purple"
                        ],
                        [
                            "value": 1,
                            "id": 1,
                            "title": "Blue"
                        ],
                        [
                            "value": 2,
                            "id": 2,
                            "title": "Green"
                        ]
                    ]
                ];
                
                window.rootViewController = controller;
            }
            
            afterEach {
                controller.dismiss(animated: false, completion: nil);
                window.rootViewController = nil;
                controller = nil;
            }
            
            it("non edit mode") {
                radioFieldView = RadioFieldView(field: field, editMode: false, value: "Purple");
                radioFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(radioFieldView)
                radioFieldView.autoPinEdgesToSuperviewEdges();
                
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
                radioFieldView = RadioFieldView(field: field);
                radioFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(radioFieldView)
                radioFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                expect(radioFieldView.isEmpty()) == true;
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
                radioFieldView = RadioFieldView(field: field, value: "Purple");
                radioFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(radioFieldView)
                radioFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                expect(radioFieldView.isEmpty()) == false;
                
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
                radioFieldView = RadioFieldView(field: field, delegate: delegate);
                radioFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(radioFieldView)
                radioFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view = view;
                tester().waitForView(withAccessibilityLabel: "field8 Purple radio");
                tester().tapView(withAccessibilityLabel: "field8 Purple radio")
                expect(radioFieldView.getValue()).to(equal("Purple"));
            }
            
            it("required field should show status") {
                field[FieldKey.required.key] = true;
                radioFieldView = RadioFieldView(field: field);
                radioFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(radioFieldView)
                radioFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                expect(radioFieldView.isEmpty()) == true;
                radioFieldView.setValid(radioFieldView.isValid());
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
                radioFieldView = RadioFieldView(field: field);
                radioFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(radioFieldView)
                radioFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                expect(radioFieldView.isEmpty()) == true;
                radioFieldView.setValid(radioFieldView.isValid());
                radioFieldView.setValue("Purple");
                expect(radioFieldView.getValue()) == "Purple";
                expect(radioFieldView.isEmpty()) == false;
                radioFieldView.setValid(radioFieldView.isValid());
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

//
//  MultiDropdownFieldViewTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 2/24/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Nimble_Snapshots

@testable import MAGE

class MultiDropdownFieldViewTests: KIFSpec {
    
    override func spec() {
        
        describe("MultiDropdownFieldView") {
            let recordSnapshots = false;
            var completeTest = false;
            
            var controller: UIViewController!
            var window: UIWindow!;
            
            var multidropdownFieldView: MultiDropdownFieldView!
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
            
            it("initial value set with multiple values") {
                multidropdownFieldView = MultiDropdownFieldView(field: field, value: ["Hello", "hi"]);
                multidropdownFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(multidropdownFieldView)
                multidropdownFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                expect(multidropdownFieldView.isEmpty()) == false;
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("non edit mode multiple values") {
                multidropdownFieldView = MultiDropdownFieldView(field: field, editMode: false, value: ["Hello", "hi"]);
                multidropdownFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(multidropdownFieldView)
                multidropdownFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                expect(multidropdownFieldView.isEmpty()) == false;
                
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
                multidropdownFieldView = MultiDropdownFieldView(field: field);
                multidropdownFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(multidropdownFieldView)
                multidropdownFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                expect(multidropdownFieldView.isEmpty()) == true;
                multidropdownFieldView.setValue(["green", "purple"]);
                expect(multidropdownFieldView.isEmpty()) == false;
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("multi required field should show status") {
                field[FieldKey.required.key] = true;
                multidropdownFieldView = MultiDropdownFieldView(field: field);
                multidropdownFieldView.applyTheme(withScheme: MAGEScheme.scheme());
                
                view.addSubview(multidropdownFieldView)
                multidropdownFieldView.autoPinEdgesToSuperviewEdges();
                
                controller.view.addSubview(view);
                expect(multidropdownFieldView.isEmpty()) == true;
                multidropdownFieldView.setValid(multidropdownFieldView.isValid());
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

//
//  ObservationFormViewTests.swift
//  MAGE
//
//  Created by Daniel Barela on 5/27/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Nimble_Snapshots

@testable import MAGE

//class MockDateFieldDelegate: NSObject, ObservationEditListener {
//    var fieldChangedCalled = false;
//    var newValue: String? = nil;
//    func observationField(_ field: Any!, valueChangedTo value: Any!, reloadCell reload: Bool) {
//        fieldChangedCalled = true;
//        newValue = value as? String;
//    }
//}

//extension EditDateView {
//    func getDatePicker() -> UIDatePicker {
//        return datePicker;
//    }
//}

class ObservationFormViewTests: QuickSpec {
    
    override func spec() {
        
        describe("ObservationFormView") {
            let recordSnapshots = false;
            var completeTest = false;

            var controller: UIViewController!
            var window: UIWindow!;
            
            var observation: Observation!;
            var formView: ObservationFormView!
            var view: UIView!
            var eventForm: [String:Any]!
            var form: NSMutableDictionary!
            
            func maybeRecordSnapshot(_ view: UIView, recordThisSnapshot: Bool = false, doneClosure: (() -> Void)?) {
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
                completeTest = false;
                window = UIWindow(forAutoLayout: ());
                window.autoSetDimension(.width, toSize: 300);
                
                controller = UIViewController();
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
                window.makeKeyAndVisible();
                
                eventForm = FormBuilder.createFormWithAllFieldTypes();
//                print("event form from builder", eventForm);
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
                
                observation = ObservationBuilder.createBaseObservation();
                form = NSMutableDictionary();
            }
            
            it("no initial value") {
                formView = ObservationFormView(observation: observation, form: form, eventForm: eventForm, formIndex: 1);

                view.addSubview(formView)
                formView.autoPinEdgesToSuperviewEdges();
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
        }
    }
}

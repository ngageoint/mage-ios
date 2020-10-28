//
//  CommonFieldsViewTests.swift
//  MAGE
//
//  Created by Daniel Barela on 6/1/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Nimble_Snapshots

@testable import MAGE

class CommonFieldsViewTests: QuickSpec {
    
    override func spec() {
        
        describe("CommonFieldsView") {
            var field: [String: Any]!
            let recordSnapshots = false;
            Nimble_Snapshots.setNimbleTolerance(0.1);
            
            var commonFieldsView: CommonFieldsView!
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
                window.makeKeyAndVisible();
                
                field = ["title": "Field Title"];
                
                UserDefaults.standard.set(0, forKey: "mapType");
                UserDefaults.standard.set(false, forKey: "showMGRS");
                UserDefaults.standard.synchronize();
            }
            
            afterEach {
                TestHelpers.clearAndSetUpStack();
            }
            
            it("empty observation") {
                var completeTest = false;
                
//                let mockMapDelegate = MockMapViewDelegate()
                
//                mockMapDelegate.mapDidFinishRenderingClosure = { mapView, fullRendered in
//                    maybeRecordSnapshot(view, doneClosure: {
//                        completeTest = true;
//                    })
//                }
                
                let observation = ObservationBuilder.createBlankObservation();
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                controller.viewDidLoadClosure = {
                    commonFieldsView = CommonFieldsView(observation: observation);
                    
                    view.addSubview(commonFieldsView)
                    commonFieldsView.autoPinEdgesToSuperviewEdges();
                    maybeRecordSnapshot(view, doneClosure: {
                        completeTest = true;
                    })
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("point observation") {
                var completeTest = false;
                
                let observation = ObservationBuilder.createPointObservation();
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                controller.viewDidLoadClosure = {
                    commonFieldsView = CommonFieldsView(observation: observation);
                    
                    view.addSubview(commonFieldsView)
                    commonFieldsView.autoPinEdgesToSuperviewEdges();
                    maybeRecordSnapshot(view, doneClosure: {
                        completeTest = true;
                    })
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("line observation") {
                var completeTest = false;
                
                let observation = ObservationBuilder.createLineObservation();
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                controller.viewDidLoadClosure = {
                    commonFieldsView = CommonFieldsView(observation: observation);
                    
                    view.addSubview(commonFieldsView)
                    commonFieldsView.autoPinEdgesToSuperviewEdges();
                    maybeRecordSnapshot(view, doneClosure: {
                        completeTest = true;
                    })
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("polygon observation") {
                var completeTest = false;
                
                let observation = ObservationBuilder.createPolygonObservation();
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                
                controller.viewDidLoadClosure = {
                    commonFieldsView = CommonFieldsView(observation: observation);
                    
                    view.addSubview(commonFieldsView)
                    commonFieldsView.autoPinEdgesToSuperviewEdges();
                    maybeRecordSnapshot(view, doneClosure: {
                        completeTest = true;
                    })
                }
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
        }
    }
}

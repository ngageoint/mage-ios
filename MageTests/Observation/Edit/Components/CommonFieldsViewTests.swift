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

class CommonFieldsViewTests: KIFSpec {
    
    override func spec() {
        
        describe("CommonFieldsView") {
            let recordSnapshots = false;
            Nimble_Snapshots.setNimbleTolerance(0.1);
            
            var commonFieldsView: CommonFieldsView!
            var controller: UIViewController!
            var window: UIWindow!;
            
            func maybeRecordSnapshot(_ view: UIView, recordThisSnapshot: Bool = false, doneClosure: (() -> Void)?) {
                print("Record snapshot?", recordSnapshots);
                if (recordSnapshots || recordThisSnapshot) {
                    DispatchQueue.global(qos: .userInitiated).async {
                        Thread.sleep(forTimeInterval: 5.0);
                        DispatchQueue.main.async {
                            expect(view) == recordSnapshot(usesDrawRect: true);
                            doneClosure?();
                        }
                    }
                } else {
                    doneClosure?();
                }
            }
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();
                window = UIWindow(frame: UIScreen.main.bounds);
                window.makeKeyAndVisible();
                
                controller = UIViewController();
                window.rootViewController = controller;
                                
                UserDefaults.standard.set(0, forKey: "mapType");
                UserDefaults.standard.set(false, forKey: "showMGRS");
                UserDefaults.standard.synchronize();
            }
            
            afterEach {
                tester().waitForAnimationsToFinish();
                waitUntil { done in
                    controller.dismiss(animated: false, completion: {
                        done();
                    });
                }
                controller = nil;
                window.resignKey();
                window.rootViewController = nil;
                window = nil;
                TestHelpers.cleanUpStack();
            }
            
            it("empty observation") {
                var completeTest = false;

                let observation = ObservationBuilder.createBlankObservation();
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));

                commonFieldsView = CommonFieldsView(observation: observation);

                controller.view.addSubview(commonFieldsView)
                commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
                
                maybeRecordSnapshot(commonFieldsView, doneClosure: {
                    completeTest = true;
                })

                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(commonFieldsView).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }

            it("point observation") {
                var completeTest = false;

                let observation = ObservationBuilder.createPointObservation();
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));

                commonFieldsView = CommonFieldsView(observation: observation);

                controller.view.addSubview(commonFieldsView)
                commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
                maybeRecordSnapshot(commonFieldsView, doneClosure: {
                    completeTest = true;
                })

                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(commonFieldsView).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }

            it("line observation") {
                var completeTest = false;

                let observation = ObservationBuilder.createLineObservation();
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));

                commonFieldsView = CommonFieldsView(observation: observation);

                controller.view.addSubview(commonFieldsView)
                commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
                maybeRecordSnapshot(commonFieldsView, doneClosure: {
                    completeTest = true;
                })

                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(commonFieldsView).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }

            it("polygon observation") {
                var completeTest = false;

                let observation = ObservationBuilder.createPolygonObservation();
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));

                commonFieldsView = CommonFieldsView(observation: observation);

                controller.view.addSubview(commonFieldsView)
                commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
                maybeRecordSnapshot(commonFieldsView, doneClosure: {
                    completeTest = true;
                })

                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(commonFieldsView).toEventually(haveValidSnapshot(usesDrawRect: true), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
        }
    }
}

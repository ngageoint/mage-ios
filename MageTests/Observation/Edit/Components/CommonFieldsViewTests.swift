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
        
        let formatter = DateFormatter();
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
        formatter.locale = Locale(identifier: "en_US_POSIX");
        
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
                                
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.showMGRS = false;
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
                commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());

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
                commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());
                
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
                commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());
                
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
                commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());
                
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
            
            describe("CommonFieldTests No UI") {
                it("empty observation") {
                    let observation = ObservationBuilder.createBlankObservation();
                    ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                    
                    commonFieldsView = CommonFieldsView(observation: observation);
                    commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());

                    controller.view.addSubview(commonFieldsView)
                    commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
                    expect(viewTester().usingLabel("geometry")?.view).toEventuallyNot(beNil());
                    expect(viewTester().usingLabel("timestamp")?.view).toEventuallyNot(beNil());
                    
                    viewTester().usingLabel("timestamp")?.expect(toContainText: (formatter.date(from: (observation.properties?["timestamp"] as! String) )! as NSDate).formattedDisplay());
                    expect((viewTester().usingLabel("location geometry")!.view as! MDCButton).currentTitle) == "NO LOCATION SET"
                    expect(commonFieldsView.checkValidity()).to(beTrue());
                    expect(commonFieldsView.checkValidity(enforceRequired: true)).to(beFalse());
                }
                
                it("empty observation set geometry") {
                    let observation = ObservationBuilder.createBlankObservation();
                    ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                    
                    let mockFieldSelectionDelegate: MockFieldDelegate = MockFieldDelegate();
                    
                    commonFieldsView = CommonFieldsView(observation: observation, fieldSelectionDelegate: mockFieldSelectionDelegate);
                    commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());
                    
                    controller.view.addSubview(commonFieldsView)
                    commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
                    expect(viewTester().usingLabel("geometry")?.view).toEventuallyNot(beNil());
                    expect(viewTester().usingLabel("timestamp")?.view).toEventuallyNot(beNil());
                    
                    viewTester().usingLabel("timestamp")?.expect(toContainText: (formatter.date(from: (observation.properties?["timestamp"] as! String) )! as NSDate).formattedDisplay());
                    expect((viewTester().usingLabel("location geometry")!.view as! MDCButton).currentTitle) == "NO LOCATION SET"
                    expect(commonFieldsView.checkValidity()).to(beTrue());
                    expect(commonFieldsView.checkValidity(enforceRequired: true)).to(beFalse());
                    
                    tester().tapView(withAccessibilityLabel: "geometry");
                    expect(mockFieldSelectionDelegate.launchFieldSelectionViewControllerCalled).to(beTrue());
                    expect(mockFieldSelectionDelegate.viewControllerToLaunch).toNot(beNil());
                    let nc = UINavigationController(rootViewController: mockFieldSelectionDelegate.viewControllerToLaunch!);
                    controller.present(nc, animated: false, completion: nil);
                    tester().tapView(withAccessibilityLabel: "Done");
                    expect((viewTester().usingLabel("location geometry")!.view as! MDCButton).currentTitle) == "1.00000, 1.00000"
                }
                
                it("empty observation set date") {
                    let observation = ObservationBuilder.createBlankObservation();
                    ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                    
                    let initialTime: String = observation.properties?["timestamp"] as! String;
                    
                    commonFieldsView = CommonFieldsView(observation: observation);
                    commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());
                    
                    controller.view.addSubview(commonFieldsView)
                    commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
                    expect(viewTester().usingLabel("geometry")?.view).toEventuallyNot(beNil());
                    expect(viewTester().usingLabel("timestamp")?.view).toEventuallyNot(beNil());
                    
                    viewTester().usingLabel("timestamp")?.expect(toContainText: (formatter.date(from: initialTime)! as NSDate).formattedDisplay());
                    expect((viewTester().usingLabel("location geometry")!.view as! MDCButton).currentTitle) == "NO LOCATION SET"
                    expect(commonFieldsView.checkValidity()).to(beTrue());
                    expect(commonFieldsView.checkValidity(enforceRequired: true)).to(beFalse());
                    
                    tester().tapView(withAccessibilityLabel: "timestamp");
                    
                    tester().waitForAnimationsToFinish();
                    tester().waitForView(withAccessibilityLabel: "timestamp Date Picker");
                    tester().selectDatePickerValue(["Nov 2", "7", "00", "AM"], with: .forwardFromCurrentValue);
                    tester().tapView(withAccessibilityLabel: "Done");
                    
                    let newTime: String = observation.properties?["timestamp"] as! String;
                    expect(newTime) != initialTime;
                    viewTester().usingLabel("timestamp")?.expect(toContainText: (formatter.date(from: newTime)! as NSDate).formattedDisplay());
                }
                
                it("point observation") {
                    let observation = ObservationBuilder.createPointObservation();
                    ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                    
                    commonFieldsView = CommonFieldsView(observation: observation);
                    commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());

                    controller.view.addSubview(commonFieldsView)
                    commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
                    expect(viewTester().usingLabel("geometry")?.view).toEventuallyNot(beNil());
                    expect(viewTester().usingLabel("timestamp")?.view).toEventuallyNot(beNil());
                    
                    viewTester().usingLabel("timestamp")?.expect(toContainText: (formatter.date(from: (observation.properties?["timestamp"] as! String) )! as NSDate).formattedDisplay());
                    expect((viewTester().usingLabel("location geometry")!.view as! MDCButton).currentTitle) == "40.00850, -105.26780"
                    expect(commonFieldsView.checkValidity()).to(beTrue());
                    expect(commonFieldsView.checkValidity(enforceRequired: true)).to(beTrue());
                }
                
                it("line observation") {
                    let observation = ObservationBuilder.createLineObservation();
                    ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                    
                    commonFieldsView = CommonFieldsView(observation: observation);
                    commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());

                    controller.view.addSubview(commonFieldsView)
                    commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
                    expect(viewTester().usingLabel("geometry")?.view).toEventuallyNot(beNil());
                    expect(viewTester().usingLabel("timestamp")?.view).toEventuallyNot(beNil());
                    
                    viewTester().usingLabel("timestamp")?.expect(toContainText: (formatter.date(from: (observation.properties?["timestamp"] as! String) )! as NSDate).formattedDisplay());
                    expect((viewTester().usingLabel("location geometry")!.view as! MDCButton).currentTitle) == "40.00850, -105.26655"
                    expect(commonFieldsView.checkValidity()).to(beTrue());
                    expect(commonFieldsView.checkValidity()).to(beTrue());
                    expect(commonFieldsView.checkValidity(enforceRequired: true)).to(beTrue());
                }
                
                it("polygon observation") {
                    let observation = ObservationBuilder.createPolygonObservation();
                    ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                    
                    commonFieldsView = CommonFieldsView(observation: observation);
                    commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());

                    controller.view.addSubview(commonFieldsView)
                    commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
                    expect(viewTester().usingLabel("geometry")?.view).toEventuallyNot(beNil());
                    expect(viewTester().usingLabel("timestamp")?.view).toEventuallyNot(beNil());
                    
                    viewTester().usingLabel("timestamp")?.expect(toContainText: (formatter.date(from: (observation.properties?["timestamp"] as! String) )! as NSDate).formattedDisplay());
                    expect((viewTester().usingLabel("location geometry")!.view as! MDCButton).currentTitle) == "40.00935, -105.26655"
                    expect(commonFieldsView.checkValidity()).to(beTrue());
                    expect(commonFieldsView.checkValidity()).to(beTrue());
                    expect(commonFieldsView.checkValidity(enforceRequired: true)).to(beTrue());
                }
            }
        }
    }
}

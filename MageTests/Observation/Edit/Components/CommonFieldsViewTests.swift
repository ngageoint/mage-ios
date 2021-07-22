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
//import Nimble_Snapshots

@testable import MAGE

class CommonFieldsViewTests: KIFSpec {
    
    override func spec() {
        
        let formatter = DateFormatter();
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
        formatter.locale = Locale(identifier: "en_US_POSIX");
        
        describe("CommonFieldsView") {
            var commonFieldsView: CommonFieldsView!
            var controller: UIViewController!
            var window: UIWindow!;
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();
                
                controller = UIViewController();
                window = TestHelpers.getKeyWindowVisible();
                window.rootViewController = controller;
                                
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.showMGRS = false;
                
//                Nimble_Snapshots.setNimbleTolerance(0.1);
//                Nimble_Snapshots.recordAllSnapshots()
            }
            
            afterEach {
                commonFieldsView.removeFromSuperview();
                commonFieldsView = nil;
                controller.dismiss(animated: false, completion: nil);
                controller = nil;
                window.rootViewController = nil;
                TestHelpers.clearAndSetUpStack();
            }
            
            it("empty observation") {
                let observation = ObservationBuilder.createBlankObservation();
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));

                commonFieldsView = CommonFieldsView(observation: observation);
                commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());

                controller.view.addSubview(commonFieldsView)
                commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
                
                tester().wait(forTimeInterval: 5.0);
//                expect(commonFieldsView).to(haveValidSnapshot());
            }

            it("point observation") {
                let observation = ObservationBuilder.createPointObservation();
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));

                commonFieldsView = CommonFieldsView(observation: observation);
                commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());
                
                controller.view.addSubview(commonFieldsView)
                commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
                tester().wait(forTimeInterval: 5.0);
//                expect(commonFieldsView).to(haveValidSnapshot());
            }

            it("line observation") {
                let observation = ObservationBuilder.createLineObservation();
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));

                commonFieldsView = CommonFieldsView(observation: observation);
                commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());
                
                controller.view.addSubview(commonFieldsView)
                commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
                tester().wait(forTimeInterval: 5.0);
//                expect(commonFieldsView).to(haveValidSnapshot());
            }

            it("polygon observation") {
                let observation = ObservationBuilder.createPolygonObservation();
                ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));

                commonFieldsView = CommonFieldsView(observation: observation);
                commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());
                
                controller.view.addSubview(commonFieldsView)
                commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
                tester().wait(forTimeInterval: 5.0);
//                expect(commonFieldsView).to(haveValidSnapshot());
            }
            
            describe("CommonFieldTests No UI") {
                it("empty observation") {
                    let observation = ObservationBuilder.createBlankObservation();
                    ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                    
                    commonFieldsView = CommonFieldsView(observation: observation);
                    commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());

                    controller.view.addSubview(commonFieldsView)
                    commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
                    
                    expect(viewTester().usingLabel("geometry")?.view).toNot(beNil());
                    expect(viewTester().usingLabel("timestamp")?.view).toNot(beNil());
                    
                    viewTester().usingLabel("timestamp")?.expect(toContainText: (formatter.date(from: (observation.properties?["timestamp"] as! String) )! as NSDate).formattedDisplay());
                    expect((viewTester().usingLabel("geometry value")!.view as! MDCFilledTextField).text) == ""
                    expect(commonFieldsView.checkValidity()).to(beTrue());
                    expect(commonFieldsView.checkValidity(enforceRequired: true)).to(beFalse());
                }
                
                it("empty observation set geometry") {
                    let observation = ObservationBuilder.createBlankObservation();
                    ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                    window.rootViewController = nil;
                    let nc = UINavigationController(rootViewController: controller);
                    window.rootViewController = nc;
                    
                    let mockFieldSelectionDelegate: MockFieldDelegate = MockFieldDelegate();
                    
                    commonFieldsView = CommonFieldsView(observation: observation, fieldSelectionDelegate: mockFieldSelectionDelegate);
                    commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());
                    
                    controller.view.addSubview(commonFieldsView)
                    commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
                    expect(viewTester().usingLabel("geometry")?.view).toNot(beNil());
                    expect(viewTester().usingLabel("timestamp")?.view).toNot(beNil());
                    
                    viewTester().usingLabel("timestamp")?.expect(toContainText: (formatter.date(from: (observation.properties?["timestamp"] as! String) )! as NSDate).formattedDisplay());
                    expect((viewTester().usingLabel("geometry value")!.view as! MDCFilledTextField).text) == ""
                    expect(commonFieldsView.checkValidity()).to(beTrue());
                    expect(commonFieldsView.checkValidity(enforceRequired: true)).to(beFalse());
                    
                    tester().tapView(withAccessibilityLabel: "geometry");
                    expect(mockFieldSelectionDelegate.launchFieldSelectionViewControllerCalled).to(beTrue());
                    expect(mockFieldSelectionDelegate.viewControllerToLaunch).toNot(beNil());
                    
                    nc.pushViewController(mockFieldSelectionDelegate.viewControllerToLaunch!, animated: false);
                    viewTester().usingLabel("Geometry Edit Map").longPress();
                    tester().tapView(withAccessibilityLabel: "Apply");
                    expect((viewTester().usingLabel("geometry value")!.view as! MDCFilledTextField).text) != ""
                    
                    expect(UIApplication.getTopViewController()).toNot(beAnInstanceOf(mockFieldSelectionDelegate.viewControllerToLaunch!.classForCoder));
                    
                    nc.popToRootViewController(animated: false);
                }
                
                it("empty observation set date") {
                    let observation = ObservationBuilder.createBlankObservation();
                    ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
                    
                    let initialTime: String = observation.properties?["timestamp"] as! String;
                    
                    commonFieldsView = CommonFieldsView(observation: observation);
                    commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());
                    
                    controller.view.addSubview(commonFieldsView)
                    commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
                    expect(viewTester().usingLabel("geometry")?.view).toNot(beNil());
                    expect(viewTester().usingLabel("timestamp")?.view).toNot(beNil());
                    
                    viewTester().usingLabel("timestamp")?.expect(toContainText: (formatter.date(from: initialTime)! as NSDate).formattedDisplay());
                    expect((viewTester().usingLabel("geometry value")!.view as! MDCFilledTextField).text) == ""
                    expect(commonFieldsView.checkValidity()).to(beTrue());
                    expect(commonFieldsView.checkValidity(enforceRequired: true)).to(beFalse());
                    TestHelpers.printAllAccessibilityLabelsInWindows();
                    tester().tapView(withAccessibilityLabel: "timestamp");
                    
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
                    expect((viewTester().usingLabel("geometry value")!.view as! MDCFilledTextField).text) == "40.00850, -105.26780 "
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
                    expect((viewTester().usingLabel("geometry value")!.view as! MDCFilledTextField).text) == "40.00850, -105.26655 "
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
                    expect(viewTester().usingLabel("geometry")?.view).toNot(beNil());
                    expect(viewTester().usingLabel("timestamp")?.view).toNot(beNil());
                    
                    viewTester().usingLabel("timestamp")?.expect(toContainText: (formatter.date(from: (observation.properties?["timestamp"] as! String) )! as NSDate).formattedDisplay());
                    expect((viewTester().usingLabel("geometry value")!.view as! MDCFilledTextField).text) == "40.00935, -105.26655 "
                    expect(commonFieldsView.checkValidity()).to(beTrue());
                    expect(commonFieldsView.checkValidity(enforceRequired: true)).to(beTrue());
                }
            }
        }
    }
}

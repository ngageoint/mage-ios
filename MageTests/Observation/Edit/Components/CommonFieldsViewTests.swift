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

class CommonFieldsViewTests: AsyncMageCoreDataTestCase {
    var commonFieldsView: CommonFieldsView!
    var controller: UIViewController!
    var window: UIWindow!;
    let formatter = DateFormatter();

    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        UserDefaults.standard.mapType = 0;
        UserDefaults.standard.locationDisplay = .latlng;
        controller = UIViewController();
        window = TestHelpers.getKeyWindowVisible();
        window.rootViewController = controller;
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ";
        formatter.locale = Locale(identifier: "en_US_POSIX");
    }
    
    @MainActor
    override func tearDown() async throws {
        try await super.tearDown()
        commonFieldsView.removeFromSuperview();
        commonFieldsView = nil;
        controller.dismiss(animated: false, completion: nil);
        controller = nil;
        window.rootViewController = nil;
    }

    @MainActor
    func testEmptyObservation() {
//            it("empty observation") {
        let observation = ObservationBuilder.createBlankObservation();
        ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));

        commonFieldsView = CommonFieldsView(observation: observation);
        commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());

                controller.view.addSubview(commonFieldsView)
        commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
        
        tester().wait(forTimeInterval: 5.0);
//                expect(commonFieldsView).to(haveValidSnapshot());
    }

    @MainActor
    func testPointObservation() {
//            it("point observation") {
        let observation = ObservationBuilder.createPointObservation();
        ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));

        commonFieldsView = CommonFieldsView(observation: observation);
        commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());
        
        controller.view.addSubview(commonFieldsView)
        commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
        tester().wait(forTimeInterval: 5.0);
//                expect(commonFieldsView).to(haveValidSnapshot());
    }

    @MainActor
    func testLineObservation() {
//            it("line observation") {
        let observation = ObservationBuilder.createLineObservation();
        ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));

        commonFieldsView = CommonFieldsView(observation: observation);
        commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());
        
        controller.view.addSubview(commonFieldsView)
        commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
        tester().wait(forTimeInterval: 5.0);
//                expect(commonFieldsView).to(haveValidSnapshot());
    }

    @MainActor
    func testPolygonObservation() {
//            it("polygon observation") {
        let observation = ObservationBuilder.createPolygonObservation();
        ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));

        commonFieldsView = CommonFieldsView(observation: observation);
        commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());
        
        controller.view.addSubview(commonFieldsView)
        commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
        tester().wait(forTimeInterval: 5.0);
//                expect(commonFieldsView).to(haveValidSnapshot());
    }
          
    @MainActor
    func testEmptyObservation2() {
//            describe("CommonFieldTests No UI") {
//                it("empty observation") {
        let observation = ObservationBuilder.createBlankObservation();
        ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
        
        commonFieldsView = CommonFieldsView(observation: observation);
        commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());

        controller.view.addSubview(commonFieldsView)
        commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
        
        expect(self.viewTester().usingLabel("geometry")?.view).toNot(beNil());
        expect(self.viewTester().usingLabel("timestamp")?.view).toNot(beNil());
        
        viewTester().usingLabel("timestamp")?.expect(toContainText: (formatter.date(from: (observation.properties?["timestamp"] as! String) )! as NSDate).formattedDisplay());
        expect((self.viewTester().usingLabel("geometry value")!.view as! MDCFilledTextField).text) == ""
        expect(self.commonFieldsView.checkValidity()).to(beTrue());
        expect(self.commonFieldsView.checkValidity(enforceRequired: true)).to(beFalse());
    }
         
    @MainActor
    func testEmptyObservationSetGeometry() {
//                it("empty observation set geometry") {
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
        expect(self.viewTester().usingLabel("geometry")?.view).toNot(beNil());
        expect(self.viewTester().usingLabel("timestamp")?.view).toNot(beNil());
        
        viewTester().usingLabel("timestamp")?.expect(toContainText: (formatter.date(from: (observation.properties?["timestamp"] as! String) )! as NSDate).formattedDisplay());
        expect((self.viewTester().usingLabel("geometry value")!.view as! MDCFilledTextField).text) == ""
        expect(self.commonFieldsView.checkValidity()).to(beTrue());
        expect(self.commonFieldsView.checkValidity(enforceRequired: true)).to(beFalse());
        
        tester().tapView(withAccessibilityLabel: "geometry");
        expect(mockFieldSelectionDelegate.launchFieldSelectionViewControllerCalled).to(beTrue());
        expect(mockFieldSelectionDelegate.viewControllerToLaunch).toNot(beNil());
        
        nc.pushViewController(mockFieldSelectionDelegate.viewControllerToLaunch!, animated: false);
        viewTester().usingLabel("Geometry Edit Map").longPress();
        tester().tapView(withAccessibilityLabel: "Apply");
        expect((self.viewTester().usingLabel("geometry value")!.view as! MDCFilledTextField).text) != ""
        
        expect(UIApplication.getTopViewController()).toNot(beAnInstanceOf(mockFieldSelectionDelegate.viewControllerToLaunch!.classForCoder));
        
        nc.popToRootViewController(animated: false);
    }
          
    @MainActor
    func testEmptyObservationSetDate() {
//                it("empty observation set date") {
        let observation = ObservationBuilder.createBlankObservation();
        ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
        
        let initialTime: String = observation.properties?["timestamp"] as! String;
        
        commonFieldsView = CommonFieldsView(observation: observation);
        commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());
        
        controller.view.addSubview(commonFieldsView)
        commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
        expect(self.viewTester().usingLabel("geometry")?.view).toNot(beNil());
        expect(self.viewTester().usingLabel("timestamp")?.view).toNot(beNil());
        
        viewTester().usingLabel("timestamp")?.expect(toContainText: (formatter.date(from: initialTime)! as NSDate).formattedDisplay());
        expect((self.viewTester().usingLabel("geometry value")!.view as! MDCFilledTextField).text) == ""
        expect(self.commonFieldsView.checkValidity()).to(beTrue());
        expect(self.commonFieldsView.checkValidity(enforceRequired: true)).to(beFalse());
        TestHelpers.printAllAccessibilityLabelsInWindows();
        tester().tapView(withAccessibilityLabel: "timestamp");
        
        tester().waitForView(withAccessibilityLabel: "timestamp Date Picker");
        tester().selectDatePickerValue(["Nov 2", "7", "00", "AM"], with: .forwardFromCurrentValue);
        tester().tapView(withAccessibilityLabel: "Done");
        
        let newTime: String = observation.properties?["timestamp"] as! String;
        expect(newTime) != initialTime;
        viewTester().usingLabel("timestamp")?.expect(toContainText: (formatter.date(from: newTime)! as NSDate).formattedDisplay());
    }
           
    @MainActor
    func testPointObservation2() async {
//                it("point observation") {
        let observation = ObservationBuilder.createPointObservation();
        ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
        
        commonFieldsView = CommonFieldsView(observation: observation);
        commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());

        controller.view.addSubview(commonFieldsView)
        commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
        
        let predicate = NSPredicate { _, _ in
            return self.viewTester().usingLabel("geometry")?.view != nil && self.viewTester().usingLabel("timestamp")?.view != nil
        }
        let viewExpectation = XCTNSPredicateExpectation(predicate: predicate, object: .none)
        await fulfillment(of: [viewExpectation], timeout: 2)
        
//        expect(self.viewTester().usingLabel("geometry")?.view).toEventuallyNot(beNil());
//        expect(self.viewTester().usingLabel("timestamp")?.view).toEventuallyNot(beNil());
        
        viewTester().usingLabel("timestamp")?.expect(toContainText: (formatter.date(from: (observation.properties?["timestamp"] as! String) )! as NSDate).formattedDisplay());
        expect((self.viewTester().usingLabel("geometry value")!.view as! MDCFilledTextField).text) == "40.0085, -105.2678 "
        expect(self.commonFieldsView.checkValidity()).to(beTrue());
        expect(self.commonFieldsView.checkValidity(enforceRequired: true)).to(beTrue());
    }
        
    @MainActor
    func testLineObservation2() async {
//                it("line observation") {
        let observation = ObservationBuilder.createLineObservation();
        ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
        
        commonFieldsView = CommonFieldsView(observation: observation);
        commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());

        controller.view.addSubview(commonFieldsView)
        commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
        let predicate = NSPredicate { _, _ in
            return self.viewTester().usingLabel("geometry")?.view != nil && self.viewTester().usingLabel("timestamp")?.view != nil
        }
        let viewExpectation = XCTNSPredicateExpectation(predicate: predicate, object: .none)
        await fulfillment(of: [viewExpectation], timeout: 2)
        
//        expect(self.viewTester().usingLabel("geometry")?.view).toEventuallyNot(beNil());
//        expect(self.viewTester().usingLabel("timestamp")?.view).toEventuallyNot(beNil());
        
        viewTester().usingLabel("timestamp")?.expect(toContainText: (formatter.date(from: (observation.properties?["timestamp"] as! String) )! as NSDate).formattedDisplay());
        expect((self.viewTester().usingLabel("geometry value")!.view as! MDCFilledTextField).text) == "40.0085, -105.2666 "
        expect(self.commonFieldsView.checkValidity()).to(beTrue());
        expect(self.commonFieldsView.checkValidity()).to(beTrue());
        expect(self.commonFieldsView.checkValidity(enforceRequired: true)).to(beTrue());
    }
           
    @MainActor
    func testPolygonObservation2() async {
//                it("polygon observation") {
        let observation = ObservationBuilder.createPolygonObservation();
        ObservationBuilder.setObservationDate(observation: observation, date: Date(timeIntervalSince1970: 10000000));
        
        commonFieldsView = CommonFieldsView(observation: observation);
        commonFieldsView.applyTheme(withScheme: MAGEScheme.scheme());

        controller.view.addSubview(commonFieldsView)
        commonFieldsView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom);
        let predicate = NSPredicate { _, _ in
            return self.viewTester().usingLabel("geometry")?.view != nil && self.viewTester().usingLabel("timestamp")?.view != nil
        }
        let viewExpectation = XCTNSPredicateExpectation(predicate: predicate, object: .none)
        await fulfillment(of: [viewExpectation], timeout: 2)
//        expect(self.viewTester().usingLabel("geometry")?.view).toNot(beNil());
//        expect(self.viewTester().usingLabel("timestamp")?.view).toNot(beNil());
        
        viewTester().usingLabel("timestamp")?.expect(toContainText: (formatter.date(from: (observation.properties?["timestamp"] as! String) )! as NSDate).formattedDisplay());
        expect((self.viewTester().usingLabel("geometry value")!.view as! MDCFilledTextField).text) == "40.0093, -105.2666 "
        expect(self.commonFieldsView.checkValidity()).to(beTrue());
        expect(self.commonFieldsView.checkValidity(enforceRequired: true)).to(beTrue());
    }
}

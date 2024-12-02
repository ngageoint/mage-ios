//
//  ObservationHeaderViewTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 12/23/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
//import Nimble_Snapshots
import OHHTTPStubs

@testable import MAGE

class ObservationHeaderViewTests: AsyncMageCoreDataTestCase {
    // TODO: These tests need to be updated to test the swiftUI view
//    var controller: UINavigationController!
//    var view: UIView!
//    var window: UIWindow!;
//    
//    @MainActor
//    override func setUp() async throws {
//        try await super.setUp()
//        if (controller != nil) {
//            controller.dismiss(animated: false);
//        }
//        TestHelpers.clearAndSetUpStack();
//        UserDefaults.standard.mapType = 0;
//        UserDefaults.standard.locationDisplay = .latlng;
//        Server.setCurrentEventId(1);
//        
//        controller = UINavigationController();
//        window = TestHelpers.getKeyWindowVisible();
//        window.rootViewController = controller;
//        view = UIView(forAutoLayout: ());
//        view.backgroundColor = .systemBackground;
//        window.makeKeyAndVisible();
//        controller.view.addSubview(view);
//        view.autoPinEdgesToSuperviewEdges();
//    }
//    
//    @MainActor
//    override func tearDown() async throws {
//        try await super.tearDown()
//        controller.dismiss(animated: false);
//        window?.resignKey();
//        window.rootViewController = nil;
//        controller = nil;
//        view = nil;
//        window = nil;
//        TestHelpers.clearAndSetUpStack();
//        HTTPStubs.removeAllStubs();
//    }
//    
//    @MainActor
//    func testInitializeTheObservationHeaderView() {
//        MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
//        MageCoreDataFixtures.addUser(userId: "userabc")
//        MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
//        let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
//        MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
//        
//        UserDefaults.standard.currentUserId = "userabc";
//        
//        let observations = Observation.mr_findAll();
//        expect(observations?.count).to(equal(1));
//        let observation: Observation = observations![0] as! Observation;
//        NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
//        let delegate = MockObservationActionsDelegate();
//        let headerView = ObservationHeaderView(observation: observation, observationActionsDelegate: delegate)
//        headerView.applyTheme(withScheme: MAGEScheme.scheme());
//        view.addSubview(headerView);
//        headerView.autoPinEdge(toSuperviewEdge: .left);
//        headerView.autoPinEdge(toSuperviewEdge: .right);
//        headerView.autoAlignAxis(toSuperviewAxis: .horizontal);
//        view = headerView;
//        TestHelpers.printAllAccessibilityLabelsInWindows();
//        tester().waitForView(withAccessibilityLabel: "important reason");
//        tester().expect(viewTester().usingLabel("important reason").view, toContainText: "This is important")
//        tester().waitForView(withAccessibilityLabel: "FLAGGED BY USER ABC");
//        TestHelpers.printAllAccessibilityLabelsInWindows();
//        tester().waitForView(withAccessibilityLabel: "USER ABC • 2020-06-05 11:21 MDT");
//        tester().waitForView(withAccessibilityLabel: "At Venue");
//        tester().waitForView(withAccessibilityLabel: "None");
//        tester().waitForView(withAccessibilityLabel: "location button")
//        expect((viewTester().usingLabel("location button")!.view as! MDCButton).currentTitle) == "40.00850, -105.26780";
//        tester().waitForView(withAccessibilityLabel: "1 FAVORITE");
//        expect((viewTester().usingLabel("favorite").view as! MDCButton).imageTintColor(for: .normal)).to(be(MDCPalette.green.accent700));
//        let importantButton = viewTester().usingLabel("important")?.usingTraits(UIAccessibilityTraits(arrayLiteral: .button)).view as! MDCButton
//        expect(importantButton.imageTintColor(for: .normal)).to(be(MDCPalette.orange.accent400));
//        
//        tester().waitForView(withAccessibilityLabel: "Observation Annotation \(observation.objectID.uriRepresentation())")
//    }
//    
//    @MainActor
//    func testTapDirectionsButton() {
//        MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
//        MageCoreDataFixtures.addUser(userId: "userabc")
//        MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
//        let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
//        MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
//        
//        UserDefaults.standard.currentUserId = "userabc";
//        
//        let observations = Observation.mr_findAll();
//        expect(observations?.count).to(equal(1));
//        let observation: Observation = observations![0] as! Observation;
//        NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
//        let delegate = MockObservationActionsDelegate();
//        let headerView = ObservationHeaderView(observation: observation, observationActionsDelegate: delegate)
//        headerView.applyTheme(withScheme: MAGEScheme.scheme());
//        view.addSubview(headerView);
//        headerView.autoPinEdge(toSuperviewEdge: .left);
//        headerView.autoPinEdge(toSuperviewEdge: .right);
//        headerView.autoAlignAxis(toSuperviewAxis: .horizontal);
//                        
//        tester().waitForView(withAccessibilityLabel: "directions");
//        tester().tapView(withAccessibilityLabel: "directions");
//        
//        expect(delegate.getDirectionsToObservationsCalled).to(beTrue());
//        
//        tester().waitForView(withAccessibilityLabel: "Observation Annotation \(observation.objectID.uriRepresentation())")
//    }
//    
//    @MainActor
//    func testTapImportantButton() {
//        MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
//        MageCoreDataFixtures.addUser(userId: "userabc")
//        MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
//        let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
//        MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
//        
//        UserDefaults.standard.currentUserId = "userabc";
//        
//        let observations = Observation.mr_findAll();
//        expect(observations?.count).to(equal(1));
//        let observation: Observation = observations![0] as! Observation;
//        NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
//        let delegate = MockObservationActionsDelegate();
//        let headerView = ObservationHeaderView(observation: observation, observationActionsDelegate: delegate)
//        headerView.applyTheme(withScheme: MAGEScheme.scheme());
//        view.addSubview(headerView);
//        headerView.autoPinEdge(toSuperviewEdge: .left);
//        headerView.autoPinEdge(toSuperviewEdge: .right);
//        headerView.autoAlignAxis(toSuperviewAxis: .horizontal);
//                        
//        tester().waitForView(withAccessibilityLabel: "important reason");
//        tester().expect(viewTester().usingLabel("important reason").view, toContainText: "This is important")
//        tester().waitForView(withAccessibilityLabel: "FLAGGED BY USER ABC");
//        tester().waitForView(withAccessibilityLabel: "USER ABC • 2020-06-05 11:21 MDT");
//        tester().waitForView(withAccessibilityLabel: "At Venue");
//        tester().waitForView(withAccessibilityLabel: "None");
//        tester().waitForView(withAccessibilityLabel: "location button")
//        expect((viewTester().usingLabel("location button")!.view as! MDCButton).currentTitle) == "40.00850, -105.26780";
//        tester().waitForView(withAccessibilityLabel: "1 FAVORITE");
//        expect((viewTester().usingLabel("favorite").view as! MDCButton).imageTintColor(for:.normal)).to(be(MDCPalette.green.accent700));
//        let importantButton = viewTester().usingLabel("important")?.usingTraits(UIAccessibilityTraits(arrayLiteral: .button)).view as! MDCButton
//        expect(importantButton.imageTintColor(for:.normal)).to(be(MDCPalette.orange.accent400));
//        tester().waitForAbsenceOfView(withAccessibilityLabel: "edit important");
//        
//        tester().waitForView(withAccessibilityLabel: "important");
//        tester().tapView(withAccessibilityLabel: "important");
//        
//        tester().waitForView(withAccessibilityLabel: "edit important");
//        tester().expect(viewTester().usingLabel("Important Description").view, toContainText: "This is important");
//        tester().clearText(fromAndThenEnterText: "New important!", intoViewWithAccessibilityLabel: "Important Description");
//        tester().tapView(withAccessibilityLabel: "Update Important");
//        expect(delegate.makeImportantCalled).to(beTrue());
//        expect(delegate.makeImportantReason) == "New important!";
//        observation.observationImportant?.reason = "New important!";
//        headerView.populate(observation: observation);
//        tester().expect(viewTester().usingLabel("important reason").view, toContainText: "New important!")
//        tester().waitForAbsenceOfView(withAccessibilityLabel: "edit important");
//        
//        tester().waitForView(withAccessibilityLabel: "Observation Annotation \(observation.objectID.uriRepresentation())")
//    }
//    
//    @MainActor
//    func testTapFavoriteButton() {
//        MageCoreDataFixtures.addEvent(remoteId: 1, name: "Event", formsJsonFile: "oneForm")
//        MageCoreDataFixtures.addUser(userId: "userabc")
//        MageCoreDataFixtures.addUserToEvent(eventId: 1, userId: "userabc")
//        let observationJson: [AnyHashable : Any] = MageCoreDataFixtures.loadObservationsJson();
//        MageCoreDataFixtures.addObservationToCurrentEvent(observationJson: observationJson)
//        
//        UserDefaults.standard.currentUserId = "userabc";
//        
//        let observations = Observation.mr_findAll();
//        expect(observations?.count).to(equal(1));
//        let observation: Observation = observations![0] as! Observation;
//        NSManagedObjectContext.mr_default().mr_saveToPersistentStoreAndWait();
//        let delegate = MockObservationActionsDelegate();
//        let headerView = ObservationHeaderView(observation: observation, observationActionsDelegate: delegate)
//        headerView.applyTheme(withScheme: MAGEScheme.scheme());
//        view.addSubview(headerView);
//        headerView.autoPinEdge(toSuperviewEdge: .left);
//        headerView.autoPinEdge(toSuperviewEdge: .right);
//        headerView.autoAlignAxis(toSuperviewAxis: .horizontal);
//                        
//        tester().waitForView(withAccessibilityLabel: "favorite");
//        tester().tapView(withAccessibilityLabel: "favorite");
//        
//        expect(delegate.favoriteCalled).to(beTrue());
//        
//        tester().waitForView(withAccessibilityLabel: "Observation Annotation \(observation.objectID.uriRepresentation())")
//    }
}

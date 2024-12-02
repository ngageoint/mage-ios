//
//  ExpandableCardCell.swift
//  MAGETests
//
//  Created by Daniel Barela on 10/28/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
//import Nimble_Snapshots
import OHHTTPStubs

@testable import MAGE

class ExpandableCardTests: XCTestCase {

    var expandableCard: ExpandableCard!
    var view: UIView!
    var controller: UIViewController!
    var window: UIWindow!;
    
    @MainActor
    override func setUp() {
        controller = UIViewController();
        view = UIView(forAutoLayout: ());
        view.autoSetDimension(.width, toSize: 300);
        view.backgroundColor = .systemBackground;
        
        controller.view.addSubview(view);
        
        window = TestHelpers.getKeyWindowVisible();
        window.rootViewController = controller;
        
        if (view != nil) {
            for subview in view.subviews {
                subview.removeFromSuperview();
            }
        }
    }
    
    @MainActor
    override func tearDown() {
        for subview in view.subviews {
            subview.removeFromSuperview();
        }
    }
    
    @MainActor
    func testHeaderSet() {
        expandableCard = ExpandableCard(header: "Header");
        expandableCard.applyTheme(withScheme: MAGEScheme.scheme());
        expect(self.expandableCard.header).to(equal("Header"));

        view.addSubview(expandableCard);
        expandableCard.autoPinEdgesToSuperviewEdges();
        
        tester().waitForAbsenceOfView(withAccessibilityLabel: "expand");
        
//                expect(view).to(haveValidSnapshot());
    }
    
    @MainActor
    func testSubheaderSet() {
        expandableCard = ExpandableCard(subheader: "Subheader");
        expandableCard.applyTheme(withScheme: MAGEScheme.scheme());
        expect(self.expandableCard.subheader).to(equal("Subheader"));

        view.addSubview(expandableCard);
        expandableCard.autoPinEdgesToSuperviewEdges();
        
        tester().waitForAbsenceOfView(withAccessibilityLabel: "expand");
        
//                expect(view).to(haveValidSnapshot());
    }
    
    @MainActor
    func testTitleSet() {
        expandableCard = ExpandableCard(title: "Title");
        expandableCard.applyTheme(withScheme: MAGEScheme.scheme());
        expect(self.expandableCard.title).to(equal("TITLE"));

        view.addSubview(expandableCard);
        expandableCard.autoPinEdgesToSuperviewEdges();
        
        tester().waitForAbsenceOfView(withAccessibilityLabel: "expand");
        
//                expect(view).to(haveValidSnapshot());
    }
    
    @MainActor
    func testImageNameSet() {
        expandableCard = ExpandableCard(systemImageName: "doc.text.fill");
        expandableCard.applyTheme(withScheme: MAGEScheme.scheme());

        view.addSubview(expandableCard);
        expandableCard.autoPinEdgesToSuperviewEdges();
        
        tester().waitForAbsenceOfView(withAccessibilityLabel: "expand");
        tester().waitForView(withAccessibilityLabel: "doc.text.fill")
        
//                expect(view).to(haveValidSnapshot());
    }
    
    @MainActor
    func testAllHeaderFieldSet() {
        expandableCard = ExpandableCard(header: "Header", subheader: "Subheader", systemImageName: "doc.text.fill", title: "Title");
        expandableCard.applyTheme(withScheme: MAGEScheme.scheme());
        
        expect(self.expandableCard.title).to(equal("TITLE"));
        expect(self.expandableCard.subheader).to(equal("Subheader"));
        expect(self.expandableCard.header).to(equal("Header"));
        
        view.addSubview(expandableCard);
        expandableCard.autoPinEdgesToSuperviewEdges();
        
        tester().waitForAbsenceOfView(withAccessibilityLabel: "expand");
        tester().waitForView(withAccessibilityLabel: "doc.text.fill")
        
//                expect(view).to(haveValidSnapshot());
    }
    
    @MainActor
    func testImageAndTitleSet() {
        expandableCard = ExpandableCard(systemImageName: "doc.text.fill", title: "Title");
        expandableCard.applyTheme(withScheme: MAGEScheme.scheme());
        
        expect(self.expandableCard.title).to(equal("TITLE"));

        view.addSubview(expandableCard);
        expandableCard.autoPinEdgesToSuperviewEdges();
        
        tester().waitForAbsenceOfView(withAccessibilityLabel: "expand");
        tester().waitForView(withAccessibilityLabel: "doc.text.fill")
        
//                expect(view).to(haveValidSnapshot());
    }
    
    @MainActor
    func testHeaderFieldSetLater() {
        expandableCard = ExpandableCard(subheader: "Subheader", systemImageName: "doc.text.fill", title: "Title");
        expandableCard.applyTheme(withScheme: MAGEScheme.scheme());
        
        expect(self.expandableCard.title).to(equal("TITLE"));
        expect(self.expandableCard.subheader).to(equal("Subheader"));
        expect(self.expandableCard.header).to(beNil());

        view.addSubview(expandableCard);
        expandableCard.autoPinEdgesToSuperviewEdges();
        
        expandableCard.header = "Header Later"
        
        tester().waitForAbsenceOfView(withAccessibilityLabel: "expand");
        tester().waitForView(withAccessibilityLabel: "doc.text.fill")
        expect(self.expandableCard.header).to(equal("Header Later"));
        
//                expect(view).to(haveValidSnapshot());
    }
    
    @MainActor
    func testSubheaderFieldSetLater() {
        expandableCard = ExpandableCard(header: "Header", systemImageName: "doc.text.fill", title: "Title");
        expandableCard.applyTheme(withScheme: MAGEScheme.scheme());
        
        expect(self.expandableCard.title).to(equal("TITLE"));
        expect(self.expandableCard.subheader).to(beNil());
        expect(self.expandableCard.header).to(equal("Header"));

        view.addSubview(expandableCard);
        expandableCard.autoPinEdgesToSuperviewEdges();
        
        expandableCard.subheader = "Subheader Later"
        
        tester().waitForAbsenceOfView(withAccessibilityLabel: "expand");
        tester().waitForView(withAccessibilityLabel: "doc.text.fill")
        expect(self.expandableCard.subheader).to(equal("Subheader Later"));
        
//                expect(view).to(haveValidSnapshot());
    }
    
    @MainActor
    func testTitleFieldSetLater() {
        expandableCard = ExpandableCard(header: "Header", subheader: "Subheader", systemImageName: "doc.text.fill");
        expandableCard.applyTheme(withScheme: MAGEScheme.scheme());
        
        expect(self.expandableCard.title).to(beNil());
        expect(self.expandableCard.subheader).to(equal("Subheader"));
        expect(self.expandableCard.header).to(equal("Header"));
        
        view.addSubview(expandableCard);
        expandableCard.autoPinEdgesToSuperviewEdges();
        
        expandableCard.title = "Title Later"
        
        tester().waitForAbsenceOfView(withAccessibilityLabel: "expand");
        tester().waitForView(withAccessibilityLabel: "doc.text.fill")
        expect(self.expandableCard.title).to(equal("TITLE LATER"));
        
//                expect(view).to(haveValidSnapshot());
    }
    
    @MainActor
    func testExpandedViewSet() {
        let expandView = UIView(forAutoLayout: ());
        expandView.backgroundColor = .blue;
        expandView.autoSetDimensions(to: CGSize(width: 300, height: 300));
        
        expandableCard = ExpandableCard(systemImageName: "doc.text.fill", title: "Title", expandedView: expandView);
        expandableCard.applyTheme(withScheme: MAGEScheme.scheme());
        
        expect(self.expandableCard.title).to(equal("TITLE"));
        expect(self.expandableCard.subheader).to(beNil());
        expect(self.expandableCard.header).to(beNil());

        view.addSubview(expandableCard);
        expandableCard.autoPinEdgesToSuperviewEdges();
        
        tester().waitForView(withAccessibilityLabel: "doc.text.fill")
        tester().waitForView(withAccessibilityLabel: "expand");
        expect(expandView.superview).toNot(beNil());
        
//                expect(view).to(haveValidSnapshot());
    }
    
    @MainActor
    func testExpandedViewSetWithHeaderInformation() {
        let expandView = UIView(forAutoLayout: ());
        expandView.backgroundColor = .blue;
        expandView.autoSetDimensions(to: CGSize(width: 300, height: 300));
        
        expandableCard = ExpandableCard(header: "Header", subheader: "Subheader", systemImageName: "doc.text.fill", title: "Title", expandedView: expandView);
        expandableCard.applyTheme(withScheme: MAGEScheme.scheme());
        
        expect(self.expandableCard.title).to(equal("TITLE"));
        expect(self.expandableCard.subheader).to(equal("Subheader"));
        expect(self.expandableCard.header).to(equal("Header"));

        view.addSubview(expandableCard);
        expandableCard.autoPinEdgesToSuperviewEdges();
        
        tester().waitForView(withAccessibilityLabel: "doc.text.fill")
        tester().waitForView(withAccessibilityLabel: "expand");
        expect(expandView.superview).toNot(beNil());
        
//                expect(view).to(haveValidSnapshot());
    }
    
    @MainActor
    func testExpandedViewSetWithHeaderInformationAllSetAfterConstruction() {
        let expandView = UIView(forAutoLayout: ());
        expandView.backgroundColor = .blue;
        expandView.autoSetDimensions(to: CGSize(width: 300, height: 300));
        
        expandableCard = ExpandableCard();
        expandableCard.applyTheme(withScheme: MAGEScheme.scheme());

        view.addSubview(expandableCard);
        expandableCard.autoPinEdgesToSuperviewEdges();
        
        expandableCard.configure(header: "Header", subheader: "Subheader", imageName: nil, systemImageName: "doc.text.fill", title: "Title", expandedView: expandView);
        
        expect(self.expandableCard.title).to(equal("TITLE"));
        expect(self.expandableCard.subheader).to(equal("Subheader"));
        expect(self.expandableCard.header).to(equal("Header"));
        TestHelpers.printAllAccessibilityLabelsInWindows()
        tester().waitForView(withAccessibilityLabel: "doc.text.fill")
        tester().waitForView(withAccessibilityLabel: "expand");
        expect(expandView.superview).toNot(beNil());
        
//                expect(view).to(haveValidSnapshot());
    }
    
    @MainActor
    func testExpandedViewIntiallySetToUnexpandedThenExpandedLater() {
        let expandView = UIView(forAutoLayout: ());
        expandView.backgroundColor = .blue;
        expandView.autoSetDimensions(to: CGSize(width: 300, height: 300));
        
        expandableCard = ExpandableCard();
        expandableCard.applyTheme(withScheme: MAGEScheme.scheme());

        view.addSubview(expandableCard);
        expandableCard.autoPinEdgesToSuperviewEdges();
        
        expandableCard.expanded = false;
        expandableCard.configure(header: "Header", subheader: "Subheader", imageName: nil, systemImageName: "doc.text.fill", title: "Title", expandedView: expandView);
        
        TestHelpers.printAllAccessibilityLabelsInWindows();
        tester().waitForAbsenceOfView(withAccessibilityLabel: "expandableArea")
        expect(self.expandableCard.title).to(equal("TITLE"));
        expect(self.expandableCard.subheader).to(equal("Subheader"));
        expect(self.expandableCard.header).to(equal("Header"));
        tester().waitForView(withAccessibilityLabel: "doc.text.fill")
        tester().waitForView(withAccessibilityLabel: "expand");
        expect(expandView.superview).toNot(beNil());
        
        expandableCard.expanded = true;
        expect(self.viewTester().usingLabel("expandableArea").view.isHidden).to(beFalse());
        
//                expect(view).to(haveValidSnapshot());
    }
    
    @MainActor
    func testWillShowUnepxandedIfSet() {
        let expandView = UIView(forAutoLayout: ());
        expandView.backgroundColor = .blue;
        expandView.autoSetDimensions(to: CGSize(width: 300, height: 300));
        
        expandableCard = ExpandableCard(header: "Header", subheader: "Subheader", imageName: nil, systemImageName: "doc.text.fill", title: "Title", expandedView: expandView);
        expandableCard.applyTheme(withScheme: MAGEScheme.scheme());
        expandableCard.expanded = false;

        view.addSubview(expandableCard);
        expandableCard.autoPinEdgesToSuperviewEdges();
        
        expect(self.expandableCard.showExpanded).to(beFalse());
        tester().waitForAbsenceOfView(withAccessibilityLabel: "expandableArea")

//                expect(view).to(haveValidSnapshot());
    }
    
    @MainActor
    func testWIllShowUnexpandedIfExpandButtonIsTapped() {
        let expandView = UIView(forAutoLayout: ());
        expandView.backgroundColor = .blue;
        expandView.autoSetDimensions(to: CGSize(width: 300, height: 300));
        
        expandableCard = ExpandableCard(header: "Header", subheader: "Subheader", imageName: nil, systemImageName: "doc.text.fill", title: "Title", expandedView: expandView);
        expandableCard.applyTheme(withScheme: MAGEScheme.scheme());

        view.addSubview(expandableCard);
        expandableCard.autoPinEdgesToSuperviewEdges();
        
        expect(self.viewTester().usingLabel("expandableArea").view.isHidden).to(beFalse());
        
        tester().waitForView(withAccessibilityLabel: "expand");
        tester().tapView(withAccessibilityLabel: "expand");
        
        expect(self.expandableCard.showExpanded).to(beFalse());
        tester().waitForAbsenceOfView(withAccessibilityLabel: "expandableArea")

//                expect(view).to(haveValidSnapshot());
    }
}

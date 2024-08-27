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

class ExpandableCardTests: KIFSpec {
    
    override func spec() {
        
        xdescribe("ExpandableCardTests") {            
            var expandableCard: ExpandableCard!
            var view: UIView!
            var controller: UIViewController!
            var window: UIWindow!;
            
            controller = UIViewController();
            view = UIView(forAutoLayout: ());
            view.autoSetDimension(.width, toSize: 300);
            view.backgroundColor = .systemBackground;
            
            controller.view.addSubview(view);
           
            beforeEach {
                window = TestHelpers.getKeyWindowVisible();
                window.rootViewController = controller;
                
                if (view != nil) {
                    for subview in view.subviews {
                        subview.removeFromSuperview();
                    }
                }
                
//                Nimble_Snapshots.setNimbleTolerance(0.0);
//                Nimble_Snapshots.recordAllSnapshots()
            }
            
            afterEach {
                for subview in view.subviews {
                    subview.removeFromSuperview();
                }
            }
            
            it("header set") {
                expandableCard = ExpandableCard(header: "Header");
                expandableCard.applyTheme(withScheme: MAGEScheme.scheme());
                expect(expandableCard.header).to(equal("Header"));

                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                tester().waitForAbsenceOfView(withAccessibilityLabel: "expand");
                
//                expect(view).to(haveValidSnapshot());
            }
            
            it("subheader set") {
                expandableCard = ExpandableCard(subheader: "Subheader");
                expandableCard.applyTheme(withScheme: MAGEScheme.scheme());
                expect(expandableCard.subheader).to(equal("Subheader"));

                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                tester().waitForAbsenceOfView(withAccessibilityLabel: "expand");
                
//                expect(view).to(haveValidSnapshot());
            }
            
            it("title set") {
                expandableCard = ExpandableCard(title: "Title");
                expandableCard.applyTheme(withScheme: MAGEScheme.scheme());
                expect(expandableCard.title).to(equal("TITLE"));

                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                tester().waitForAbsenceOfView(withAccessibilityLabel: "expand");
                
//                expect(view).to(haveValidSnapshot());
            }
            
            it("image name set") {
                expandableCard = ExpandableCard(systemImageName: "doc.text.fill");
                expandableCard.applyTheme(withScheme: MAGEScheme.scheme());

                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                tester().waitForAbsenceOfView(withAccessibilityLabel: "expand");
                tester().waitForView(withAccessibilityLabel: "doc.text.fill")
                
//                expect(view).to(haveValidSnapshot());
            }
            
            it("all header fields set") {
                expandableCard = ExpandableCard(header: "Header", subheader: "Subheader", systemImageName: "doc.text.fill", title: "Title");
                expandableCard.applyTheme(withScheme: MAGEScheme.scheme());
                
                expect(expandableCard.title).to(equal("TITLE"));
                expect(expandableCard.subheader).to(equal("Subheader"));
                expect(expandableCard.header).to(equal("Header"));
                
                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                tester().waitForAbsenceOfView(withAccessibilityLabel: "expand");
                tester().waitForView(withAccessibilityLabel: "doc.text.fill")
                
//                expect(view).to(haveValidSnapshot());
            }
            
            it("image and title set") {
                expandableCard = ExpandableCard(systemImageName: "doc.text.fill", title: "Title");
                expandableCard.applyTheme(withScheme: MAGEScheme.scheme());
                
                expect(expandableCard.title).to(equal("TITLE"));

                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                tester().waitForAbsenceOfView(withAccessibilityLabel: "expand");
                tester().waitForView(withAccessibilityLabel: "doc.text.fill")
                
//                expect(view).to(haveValidSnapshot());
            }
            
            it("header field set later") {
                expandableCard = ExpandableCard(subheader: "Subheader", systemImageName: "doc.text.fill", title: "Title");
                expandableCard.applyTheme(withScheme: MAGEScheme.scheme());
                
                expect(expandableCard.title).to(equal("TITLE"));
                expect(expandableCard.subheader).to(equal("Subheader"));
                expect(expandableCard.header).to(beNil());

                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                expandableCard.header = "Header Later"
                
                tester().waitForAbsenceOfView(withAccessibilityLabel: "expand");
                tester().waitForView(withAccessibilityLabel: "doc.text.fill")
                expect(expandableCard.header).to(equal("Header Later"));
                
//                expect(view).to(haveValidSnapshot());
            }
            
            it("subheader field set later") {
                expandableCard = ExpandableCard(header: "Header", systemImageName: "doc.text.fill", title: "Title");
                expandableCard.applyTheme(withScheme: MAGEScheme.scheme());
                
                expect(expandableCard.title).to(equal("TITLE"));
                expect(expandableCard.subheader).to(beNil());
                expect(expandableCard.header).to(equal("Header"));

                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                expandableCard.subheader = "Subheader Later"
                
                tester().waitForAbsenceOfView(withAccessibilityLabel: "expand");
                tester().waitForView(withAccessibilityLabel: "doc.text.fill")
                expect(expandableCard.subheader).to(equal("Subheader Later"));
                
//                expect(view).to(haveValidSnapshot());
            }
            
            it("title field set later") {
                expandableCard = ExpandableCard(header: "Header", subheader: "Subheader", systemImageName: "doc.text.fill");
                expandableCard.applyTheme(withScheme: MAGEScheme.scheme());
                
                expect(expandableCard.title).to(beNil());
                expect(expandableCard.subheader).to(equal("Subheader"));
                expect(expandableCard.header).to(equal("Header"));
                
                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                expandableCard.title = "Title Later"
                
                tester().waitForAbsenceOfView(withAccessibilityLabel: "expand");
                tester().waitForView(withAccessibilityLabel: "doc.text.fill")
                expect(expandableCard.title).to(equal("TITLE LATER"));
                
//                expect(view).to(haveValidSnapshot());
            }
            
            it("expanded view set") {
                let expandView = UIView(forAutoLayout: ());
                expandView.backgroundColor = .blue;
                expandView.autoSetDimensions(to: CGSize(width: 300, height: 300));
                
                expandableCard = ExpandableCard(systemImageName: "doc.text.fill", title: "Title", expandedView: expandView);
                expandableCard.applyTheme(withScheme: MAGEScheme.scheme());
                
                expect(expandableCard.title).to(equal("TITLE"));
                expect(expandableCard.subheader).to(beNil());
                expect(expandableCard.header).to(beNil());

                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                tester().waitForView(withAccessibilityLabel: "doc.text.fill")
                tester().waitForView(withAccessibilityLabel: "expand");
                expect(expandView.superview).toNot(beNil());
                
//                expect(view).to(haveValidSnapshot());
            }
            
            it("expanded view set with header information") {
                let expandView = UIView(forAutoLayout: ());
                expandView.backgroundColor = .blue;
                expandView.autoSetDimensions(to: CGSize(width: 300, height: 300));
                
                expandableCard = ExpandableCard(header: "Header", subheader: "Subheader", systemImageName: "doc.text.fill", title: "Title", expandedView: expandView);
                expandableCard.applyTheme(withScheme: MAGEScheme.scheme());
                
                expect(expandableCard.title).to(equal("TITLE"));
                expect(expandableCard.subheader).to(equal("Subheader"));
                expect(expandableCard.header).to(equal("Header"));

                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                tester().waitForView(withAccessibilityLabel: "doc.text.fill")
                tester().waitForView(withAccessibilityLabel: "expand");
                expect(expandView.superview).toNot(beNil());
                
//                expect(view).to(haveValidSnapshot());
            }
            
            it("expanded view set with header information all set after construction") {
                let expandView = UIView(forAutoLayout: ());
                expandView.backgroundColor = .blue;
                expandView.autoSetDimensions(to: CGSize(width: 300, height: 300));
                
                expandableCard = ExpandableCard();
                expandableCard.applyTheme(withScheme: MAGEScheme.scheme());

                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                expandableCard.configure(header: "Header", subheader: "Subheader", imageName: nil, systemImageName: "doc.text.fill", title: "Title", expandedView: expandView);
                
                expect(expandableCard.title).to(equal("TITLE"));
                expect(expandableCard.subheader).to(equal("Subheader"));
                expect(expandableCard.header).to(equal("Header"));
                TestHelpers.printAllAccessibilityLabelsInWindows()
                tester().waitForView(withAccessibilityLabel: "doc.text.fill")
                tester().waitForView(withAccessibilityLabel: "expand");
                expect(expandView.superview).toNot(beNil());
                
//                expect(view).to(haveValidSnapshot());
            }
            
            it("expanded view initially set to unexpanded then expanded later") {
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
                expect(expandableCard.title).to(equal("TITLE"));
                expect(expandableCard.subheader).to(equal("Subheader"));
                expect(expandableCard.header).to(equal("Header"));
                tester().waitForView(withAccessibilityLabel: "doc.text.fill")
                tester().waitForView(withAccessibilityLabel: "expand");
                expect(expandView.superview).toNot(beNil());
                
                expandableCard.expanded = true;
                expect(viewTester().usingLabel("expandableArea").view.isHidden).to(beFalse());
                
//                expect(view).to(haveValidSnapshot());
            }
            
            it("will show unexpanded if set") {
                let expandView = UIView(forAutoLayout: ());
                expandView.backgroundColor = .blue;
                expandView.autoSetDimensions(to: CGSize(width: 300, height: 300));
                
                expandableCard = ExpandableCard(header: "Header", subheader: "Subheader", imageName: nil, systemImageName: "doc.text.fill", title: "Title", expandedView: expandView);
                expandableCard.applyTheme(withScheme: MAGEScheme.scheme());
                expandableCard.expanded = false;

                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                expect(expandableCard.showExpanded).to(beFalse());
                tester().waitForAbsenceOfView(withAccessibilityLabel: "expandableArea")

//                expect(view).to(haveValidSnapshot());
            }
            
            it("will show unexpanded if expand button is tapped") {
                let expandView = UIView(forAutoLayout: ());
                expandView.backgroundColor = .blue;
                expandView.autoSetDimensions(to: CGSize(width: 300, height: 300));
                
                expandableCard = ExpandableCard(header: "Header", subheader: "Subheader", imageName: nil, systemImageName: "doc.text.fill", title: "Title", expandedView: expandView);
                expandableCard.applyTheme(withScheme: MAGEScheme.scheme());

                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                expect(viewTester().usingLabel("expandableArea").view.isHidden).to(beFalse());
                
                tester().waitForView(withAccessibilityLabel: "expand");
                tester().tapView(withAccessibilityLabel: "expand");
                
                expect(expandableCard.showExpanded).to(beFalse());
                tester().waitForAbsenceOfView(withAccessibilityLabel: "expandableArea")

//                expect(view).to(haveValidSnapshot());
            }
        }
    }
}

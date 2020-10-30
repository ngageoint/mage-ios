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
import Nimble_Snapshots
import OHHTTPStubs

@testable import MAGE

class ExpandableCardTests: KIFSpec {
    
    override func spec() {
        
        describe("ExpandableCardTests") {
            let recordSnapshots = false;
            
            var expandableCard: ExpandableCard!
            var view: UIView!
            var controller: ContainingUIViewController!
            var window: UIWindow!;
           
            func maybeRecordSnapshot(_ view: UIView, recordThisSnapshot: Bool = false, doneClosure: (() -> Void)?) {
                print("Record snapshot?", recordSnapshots);
                if (recordSnapshots || recordThisSnapshot) {
                    DispatchQueue.global(qos: .userInitiated).async {
                        Thread.sleep(forTimeInterval: 0.5);
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
                view.backgroundColor = .systemBackground;
                window.makeKeyAndVisible();
                
                UserDefaults.standard.synchronize();
            }
            
            afterEach {
            }
            
            it("header set") {
                var completeTest = false;
                
                expandableCard = ExpandableCard(header: "Header");
                expect(expandableCard.header).to(equal("Header"));

                window.rootViewController = controller;
                controller.view.addSubview(view);
                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("subheader set") {
                var completeTest = false;
                
                expandableCard = ExpandableCard(subheader: "Subheader");
                expect(expandableCard.subheader).to(equal("Subheader"));
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("title set") {
                var completeTest = false;
                
                expandableCard = ExpandableCard(title: "Title");
                expect(expandableCard.title).to(equal("TITLE"));

                window.rootViewController = controller;
                controller.view.addSubview(view);
                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("image name set") {
                var completeTest = false;
                
                expandableCard = ExpandableCard(imageName: "form");
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
//                view.autoPinEdgesToSuperviewEdges();
                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("all header fields set") {
                var completeTest = false;
                
                expandableCard = ExpandableCard(header: "Header", subheader: "Subheader", imageName: "form", title: "Title");
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("image and title set") {
                var completeTest = false;
                
                expandableCard = ExpandableCard(imageName: "form", title: "Title");
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("header field set later") {
                var completeTest = false;
                
                expandableCard = ExpandableCard(subheader: "Subheader", imageName: "form", title: "Title");
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                expandableCard.header = "Header Later"
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("subheader field set later") {
                var completeTest = false;
                
                expandableCard = ExpandableCard(header: "Header", imageName: "form", title: "Title");
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                expandableCard.subheader = "Subheader Later"
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("title field set later") {
                var completeTest = false;
                
                expandableCard = ExpandableCard(header: "Header", subheader: "Subheader", imageName: "form");
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                expandableCard.title = "Title Later"
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("expanded view set") {
                var completeTest = false;
                
                let expandView = UIView(forAutoLayout: ());
                expandView.backgroundColor = .blue;
                expandView.autoSetDimensions(to: CGSize(width: 200, height: 300));
                
                expandableCard = ExpandableCard(imageName: "form", title: "Title", expandedView: expandView);
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("expanded view set with header information") {
                var completeTest = false;
                
                let expandView = UIView(forAutoLayout: ());
                expandView.backgroundColor = .blue;
                expandView.autoSetDimensions(to: CGSize(width: 200, height: 300));
                
                expandableCard = ExpandableCard(header: "Header", subheader: "Subheader", imageName: "form", title: "Title", expandedView: expandView);
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("expanded view set with header information all set after construction") {
                var completeTest = false;
                
                let expandView = UIView(forAutoLayout: ());
                expandView.backgroundColor = .blue;
                expandView.autoSetDimensions(to: CGSize(width: 200, height: 300));
                
                expandableCard = ExpandableCard();
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                expandableCard.configure(header: "Header", subheader: "Subheader", imageName: "form", title: "Title", expandedView: expandView);
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("expanded view initially set to unexpanded then expanded later") {
                var completeTest = false;
                
                let expandView = UIView(forAutoLayout: ());
                expandView.backgroundColor = .blue;
                expandView.autoSetDimensions(to: CGSize(width: 200, height: 300));
                
                expandableCard = ExpandableCard();
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                expandableCard.expanded = false;
                expandableCard.configure(header: "Header", subheader: "Subheader", imageName: "form", title: "Title", expandedView: expandView);
                expandableCard.expanded = true;
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("will show unexpanded if set") {
                var completeTest = false;
                
                let expandView = UIView(forAutoLayout: ());
                expandView.backgroundColor = .blue;
                expandView.autoSetDimensions(to: CGSize(width: 200, height: 300));
                
                expandableCard = ExpandableCard(header: "Header", subheader: "Subheader", imageName: "form", title: "Title", expandedView: expandView);
                expandableCard.expanded = false;
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                expect(expandableCard.showExpanded).to(beFalse());
                
                maybeRecordSnapshot(view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("will show unexpanded if expand button is tapped") {
                var completeTest = false;
                
                let expandView = UIView(forAutoLayout: ());
                expandView.backgroundColor = .blue;
                expandView.autoSetDimensions(to: CGSize(width: 200, height: 300));
                
                expandableCard = ExpandableCard(header: "Header", subheader: "Subheader", imageName: "form", title: "Title", expandedView: expandView);

                window.rootViewController = controller;
                controller.view.addSubview(view);
                view.addSubview(expandableCard);
                expandableCard.autoPinEdgesToSuperviewEdges();
                
                tester().waitForView(withAccessibilityLabel: "expand");
                tester().tapView(withAccessibilityLabel: "expand");
                tester().waitForAnimationsToFinish();
                
                expect(expandableCard.showExpanded).to(beFalse());
                
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

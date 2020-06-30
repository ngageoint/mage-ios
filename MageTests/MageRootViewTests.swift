//
//  MageRootViewTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 6/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Nimble_Snapshots
import PureLayout

@testable import MAGE

@available(iOS 13.0, *)
class MageRootViewTests: KIFSpec {
    
    override func spec() {
        
        describe("MageRootView") {
            let recordSnapshots = false;
            Nimble_Snapshots.setNimbleTolerance(0.01);
            
            var controller: MageRootViewController!
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
            
            func clearAndSetUpStack() {
                MageInitializer.initializePreferences();
                MageInitializer.clearAndSetupCoreData();
            }
            
            beforeEach {
                waitUntil { done in
                    clearAndSetUpStack();
                    
                    window = UIWindow(forAutoLayout: ());
                    window.autoSetDimension(.width, toSize: 414);
                    window.autoSetDimension(.height, toSize: 896);
                    
                    window.makeKeyAndVisible();
                    
                    UserDefaults.standard.set(0, forKey: "mapType");
                    UserDefaults.standard.set(false, forKey: "showMGRS");
                    UserDefaults.standard.synchronize();
                    
                    Server.setCurrentEventId(1);
                    
                    MageCoreDataFixtures.addEvent { (success: Bool, error: Error?) in
                        done();
                    }
                }
            }
            
            afterEach {
                clearAndSetUpStack();
            }
            
            it("no feeds") {
                var completeTest = false;
                
                let iphoneStoryboard = UIStoryboard(name: "Main_iPhone", bundle: nil);
                controller = iphoneStoryboard.instantiateInitialViewController();

                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
            
                
                window.rootViewController = controller;
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
            
            it("one feed") {
                var completeTest = false;
                
                waitUntil { done in
                    MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: 1, title: "My Feed") { (success: Bool, error: Error?) in
                        done();
                    }
                }
                
                let iphoneStoryboard = UIStoryboard(name: "Main_iPhone", bundle: nil);
                controller = iphoneStoryboard.instantiateInitialViewController();
                
                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                window.rootViewController = controller;
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
            
            it("tap observations button one feed") {
                var completeTest = false;
                
                waitUntil { done in
                    MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: 1, title: "My Feed") { (success: Bool, error: Error?) in
                        done();
                    }
                }
                
                let iphoneStoryboard = UIStoryboard(name: "Main_iPhone", bundle: nil);
                controller = iphoneStoryboard.instantiateInitialViewController();
                controller.selectedIndex = 1;
                
                window.rootViewController = controller;
                
                
                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
            
            it("tap more button one feed") {
                var completeTest = false;
                
                waitUntil { done in
                    MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: 1, title: "My Feed") { (success: Bool, error: Error?) in
                        done();
                    }
                }
                
                let iphoneStoryboard = UIStoryboard(name: "Main_iPhone", bundle: nil);
                controller = iphoneStoryboard.instantiateInitialViewController();
                window.rootViewController = controller;
                
                tester().tapView(withAccessibilityLabel: "More");
//                tester().tapScreen(at: CGPoint(x: 310, y: 740));
                TestHelpers.printAllAccessibilityLabelsInWindows()
                
                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
            
            it("tap more button two feeds") {
                var completeTest = false;
                
                waitUntil { done in
                    MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: 1, title: "My Feed") { (success: Bool, error: Error?) in
                        MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: 2, title: "My Second Feed") { (success: Bool, error: Error?) in
                            done();
                        }
                    }
                }
                
                let iphoneStoryboard = UIStoryboard(name: "Main_iPhone", bundle: nil);
                controller = iphoneStoryboard.instantiateInitialViewController();
                window.rootViewController = controller;
                
                tester().tapView(withAccessibilityLabel: "More");
                //                tester().tapScreen(at: CGPoint(x: 310, y: 740));
                TestHelpers.printAllAccessibilityLabelsInWindows()
                
                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: 10, pollInterval: 1, description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: 10, pollInterval: 1, description: "Map loaded")
                }
            }
        }
    }
}

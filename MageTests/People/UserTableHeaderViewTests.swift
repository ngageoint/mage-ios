//
//  UserTableHeaderViewTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 7/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Nimble_Snapshots
import MagicalRecord

@testable import MAGE

class ContainingUIViewController: UIViewController {
    var viewDidLoadClosure: (() -> Void)?
    
    override func viewWillAppear(_ animated: Bool) {
        viewDidLoadClosure?();
    }
}

class UserTableHeaderViewTests: QuickSpec {
    
    override func spec() {
        
        describe("UserTableHeaderView") {
            
            func clearAndSetUpStack() {
                MageInitializer.initializePreferences();
                MageInitializer.clearAndSetupCoreData();
            }
            
            let recordSnapshots = false;
            Nimble_Snapshots.setNimbleTolerance(0.1);
            
            var userTableHeaderView: UserTableHeaderView!
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
                
                clearAndSetUpStack();
                MageCoreDataFixtures.quietLogging();
                window = UIWindow(forAutoLayout: ());
                window.autoSetDimension(.width, toSize: 300);
                
                controller = ContainingUIViewController();
                view = UIView(forAutoLayout: ());
                view.autoSetDimension(.width, toSize: 300);
                window.makeKeyAndVisible();
                
                Server.setCurrentEventId(1);
                UserDefaults.standard.set(0, forKey: "mapType");
                UserDefaults.standard.set(false, forKey: "showMGRS");
                UserDefaults.standard.set(nil, forKey: "currentUserId");
                UserDefaults.standard.synchronize();
            }
            
            afterEach {
                controller.dismiss(animated: false, completion: nil);
                window.rootViewController = nil;
                controller = nil;
                clearAndSetUpStack();
            }
            
            it("user view") {
                var completeTest = false;
            
                window.rootViewController = controller;
                controller.view.addSubview(view);
                waitUntil { done in
                    MageCoreDataFixtures.addUser() { (_, error: Error?) in
                        MageCoreDataFixtures.addLocation() { (_, error: Error?) in
                            print("error", error);
                            done();
                        }
                    }
                }
                
                let user: User = User.mr_findFirst()!;
                userTableHeaderView = UserTableHeaderView(forAutoLayout: ());
                userTableHeaderView.populate(user: user);
                view.addSubview(userTableHeaderView);
                userTableHeaderView.autoPinEdgesToSuperviewEdges();
                
                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
            
            it("current user view") {
                var completeTest = false;
                
                UserDefaults.standard.set("userabc", forKey: "currentUserId");
                
                window.rootViewController = controller;
                controller.view.addSubview(view);
                waitUntil { done in
                    MageCoreDataFixtures.addUser() { (_, error: Error?) in
                        MageCoreDataFixtures.addGPSLocation() { (_, error: Error?) in
                            print("error", error);
                            done();
                        }
                    }
                }
                
                let user: User = User.mr_findFirst()!;
                userTableHeaderView = UserTableHeaderView(forAutoLayout: ());
                userTableHeaderView.populate(user: user);
                view.addSubview(userTableHeaderView);
                userTableHeaderView.autoPinEdgesToSuperviewEdges();
                
                maybeRecordSnapshot(controller.view, doneClosure: {
                    completeTest = true;
                })
                
                if (recordSnapshots) {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                } else {
                    expect(completeTest).toEventually(beTrue(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Test Complete");
                    expect(controller.view).toEventually(haveValidSnapshot(), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.seconds(1), description: "Map loaded")
                }
            }
        }
        
    }
}

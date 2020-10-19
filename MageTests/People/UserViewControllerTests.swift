//
//  UserViewControllerTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 7/13/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import Nimble_Snapshots
import MagicalRecord

@testable import MAGE

class UserViewControllerTests: QuickSpec {
    
    override func spec() {
        
        describe("UserViewController") {
            
            func clearAndSetUpStack() {
                MageInitializer.initializePreferences();
                MageInitializer.clearAndSetupCoreData();
            }
            
            let recordSnapshots = false;
            Nimble_Snapshots.setNimbleTolerance(0.1);
            
            var userTableHeaderView: UserTableHeaderView!
            var view: UIView!
            var controller: UserViewController!
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
                window.autoSetDimension(.width, toSize: 414);
                window.autoSetDimension(.height, toSize: 896);
                window.makeKeyAndVisible();
                
                Server.setCurrentEventId(1);
                UserDefaults.standard.set(0, forKey: "mapType");
                UserDefaults.standard.set(false, forKey: "showMGRS");
                UserDefaults.standard.synchronize();
            }
            
            afterEach {
//                clearAndSetUpStack();
            }
            
            it("user view") {
                var completeTest = false;
                
                waitUntil { done in
                    MageCoreDataFixtures.addUser() { (_, error: Error?) in
                        MageCoreDataFixtures.addLocation() { (_, error: Error?) in
                            print("error", error);
                            MageCoreDataFixtures.addObservationToEvent()  { (_, error: Error?) in
                                print("error", error);
                                done();
                            }
                        }
                    }
                }
                
                let user: User = User.mr_findFirst()!;
                let userLastLocation: CLLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 40.0085, longitude: -105.2678), altitude: 0, horizontalAccuracy: 4.3, verticalAccuracy: 0, timestamp: Date(timeIntervalSince1970: 1));
                
                controller = UserViewController(user: user);
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
        }
    }
}

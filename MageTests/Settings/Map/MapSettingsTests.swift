//
//  MapSettingsTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 9/24/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import PureLayout
import OHHTTPStubs
import Kingfisher

@testable import MAGE

class MapSettingsTests: KIFSpec {
    
    override func spec() {
        
        describe("MapSettingsTests") {
            
            var mapSettings: MapSettings!
            var window: UIWindow!;
            
            func clearAndSetUpStack() {
                MageInitializer.initializePreferences();
                MageInitializer.clearAndSetupCoreData();
            }
            
            beforeEach {
                
                waitUntil { done in
                    clearAndSetUpStack();
                    MageCoreDataFixtures.quietLogging();
                    
                    UserDefaults.standard.set("https://magetest", forKey: "baseServerUrl");
                    UserDefaults.standard.set(0, forKey: "mapType");
                    UserDefaults.standard.set(false, forKey: "showMGRS");
                    UserDefaults.standard.synchronize();
                    
                    Server.setCurrentEventId(1);
                    
                    window = UIWindow(forAutoLayout: ());
                    window.autoSetDimension(.width, toSize: 414);
                    window.autoSetDimension(.height, toSize: 896);
                    
                    window.makeKeyAndVisible();
                    
                    MageCoreDataFixtures.addEvent { (success: Bool, error: Error?) in
                        done();
                    }
                }
            }
            
            afterEach {
                FeedService.shared.stop();
                HTTPStubs.removeAllStubs();
                clearAndSetUpStack();
            }
            
            it("should unselect a feed") {
                waitUntil { done in
                    MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary") { (success: Bool, error: Error?) in
                        done();
                    }
                }
                
                UserDefaults.standard.set(["1"], forKey: "selectedFeeds-1");
                mapSettings = MapSettings();
                window.rootViewController = mapSettings;
                tester().waitForView(withAccessibilityLabel: "feed-switch-1");
                tester().setOn(false, forSwitchWithAccessibilityLabel: "feed-switch-1");
                tester().waitForAnimationsToFinish();
                let selected = UserDefaults.standard.array(forKey: "selectedFeeds-1");
                expect(selected).to(beEmpty());
            }
        }
    }
}

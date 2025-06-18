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
            
            beforeEach {
                
                TestHelpers.clearAndSetUpStack();
                MageCoreDataFixtures.quietLogging();
                
                UserDefaults.standard.baseServerUrl = "https://magetest";
                UserDefaults.standard.mapType = 0;
                UserDefaults.standard.locationDisplay = .latlng;
                
                Server.setCurrentEventId(1);
                
                window = TestHelpers.getKeyWindowVisible();
                    
                MageCoreDataFixtures.addEvent();
            }
            
            afterEach {
                FeedService.shared.stop();
                HTTPStubs.removeAllStubs();
                TestHelpers.clearAndSetUpStack();
                MageCoreDataFixtures.clearAllData();
            }
            
            it("should unselect a feed") {
                waitUntil { done in
                    MageCoreDataFixtures.addFeedToEvent(eventId: 1, id: "1", title: "My Feed", primaryProperty: "primary", secondaryProperty: "secondary") { (success: Bool, error: Error?) in
                        done();
                    }
                }
                
                UserDefaults.standard.set(["1"], forKey: "selectedFeeds-1");
                mapSettings = MapSettings();
                mapSettings.applyTheme(withContainerScheme: MAGEScheme.scheme())
                window.rootViewController = mapSettings;
                tester().waitForAnimationsToFinish();
                tester().waitForView(withAccessibilityLabel: "feed-switch-1");
                tester().setOn(false, forSwitchWithAccessibilityLabel: "feed-switch-1");
                let selected = UserDefaults.standard.array(forKey: "selectedFeeds-1");
                expect(selected).to(beEmpty());
            }
        }
    }
}

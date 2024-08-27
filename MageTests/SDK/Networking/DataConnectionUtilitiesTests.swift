//
//  DataConnectionUtilitiesTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 12/1/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import OHHTTPStubs

@testable import MAGE

class DataConnectionUtilitiesTests: QuickSpec {
    
    override func spec() {
        
        xdescribe("DataConnectionUtilitiesTests") {
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();
            }
            
            afterEach {
                FeedService.shared.stop();
                HTTPStubs.removeAllStubs();
                TestHelpers.clearAndSetUpStack();
            }
            
            it("should get current wifi ssid") {
                // this is untestable on the simulator
                let wifiSsid = DataConnectionUtilities.getCurrentWifiSsid()
                expect(wifiSsid).to(beNil())
            }
            
            it("should get the connection type") {
                // this is all that is testable on the simulator
                let connectionType = DataConnectionUtilities.connectionType()
                expect(connectionType).to(equal(ConnectionType.wiFi))
            }
        }
    }
}

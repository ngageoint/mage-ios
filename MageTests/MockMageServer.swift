//
//  MockMageServer.swift
//  MAGETests
//
//  Created by Daniel Barela on 7/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import OHHTTPStubs

class MockMageServer {
    
    public static func initializeHttpStubs() {
        HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            return request.url == URL(string: "https://magetest/icon.png");
        }) { (request) -> HTTPStubsResponse in
            let stubPath = OHPathForFile("icon27.png", MockMageServer.self)
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        };
    }
}

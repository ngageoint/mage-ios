//
//  MockMageServer.swift
//  MAGETests
//
//  Created by Daniel Barela on 7/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import OHHTTPStubs

class MockMageServerDelegate {
    var urls: [URL?] = [];

    func urlCalled(_ url: URL?, method: String?) {
        urls.append(url);
    }
}



class MockMageServer: NSObject {
    
    public static func initializeHttpStubs() {
        HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            return request.url == URL(string: "https://magetest/icon.png");
        }) { (request) -> HTTPStubsResponse in
            let stubPath = OHPathForFile("icon27.png", MockMageServer.self)
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        };
    }
    
    @discardableResult public static func stubJSONSuccessRequest(url: String, filePath: String, delegate: MockMageServerDelegate? = nil) -> HTTPStubsDescriptor {
        let stub = HTTPStubs.stubRequests { (request) -> Bool in
            return request.url == URL(string: url);
        } withStubResponse: { (request) -> HTTPStubsResponse in
            if (delegate != nil) {
                delegate?.urlCalled(request.url, method: request.httpMethod);
            }
            let stubPath = OHPathForFile(filePath, MockMageServer.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        return stub;
    }
}

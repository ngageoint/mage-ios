//
//  ServerInfoServiceTests.swift
//  MAGETests
//
//  Created by Brent Michalski on 10/14/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
@testable import MAGE

final class ServerInfoServiceTests: XCTestCase {
    
    func test_fetchServerModules_readsStrategiesFromApi() async throws {
        let apiJSON = """
            {
                "version": 6,
                "authenticationStrategies": [
                    { "identifier": "local", "type": "local", "title":"Username/Password" },
                    { "identifier": "offline", "type": "local", "title":"Offline" }
                ],
                "disclaimer": null
            }
            """
        
        let base = URL(string: "https://magetest")!
        
        let routes = [
            TestRoute(matches: { req in
                guard let u = req.url else { return false }
                return u.host == base.host && u.path == "/api" && (req.httpMethod ?? "GET") == "GET"
            }, respond: { req in
                let data = Data(apiJSON.utf8)
                let http = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil,
                                           headerFields: ["Content-Type":"application/json"])!
                return (data, http)
            })
        ]
        
        let fakeNet = TestFakeNetwork(routes: routes)
        let svc = ServerInfoService(baseURL: base, net: fakeNet)
        
        let modules = try await svc.fetchServerModules()
        
        XCTAssertEqual(modules["local"]?["title"] as? String, "Username/Password")
        XCTAssertEqual(modules["offline"]?["type"] as? String, "local")
    }
    
    func test_testServerModules_fallsBackToApiServer() async throws {
        let serverJSON = """
            {
                      "version": 6,
                      "authenticationStrategies": [
                        { "identifier": "local", "type": "local", "title": "Username/Password" }
                      ]
                    }
            """
        
        let base = URL(string: "https://magetest")!
        
        let routes = [
            // /api -> 404 forces fallback
            TestRoute(matches: { req in
                req.url?.host == base.host && req.url?.path == "/api"
            }, respond: { req in
                let http = HTTPURLResponse(url: req.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!
                return(Data(), http)
            }),
            
            // /api/server -> success
            TestRoute(matches: { req in
                req.url?.host == base.host && req.url?.path == "/api/server"
            }, respond: { req in
                let data = Data(serverJSON.utf8)
                let http = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil,
                                           headerFields: ["Content-Type":"application/json"])!
                return (data, http)
            })
        ]
        
        let fakeNet = TestFakeNetwork(routes: routes)
        let svc = ServerInfoService(baseURL: base, net: fakeNet)
        
        let modules = try await svc.fetchServerModules()
        XCTAssertNotNil(modules["local"])
    }
}

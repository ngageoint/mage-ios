//
//  MageServerTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 4/21/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import PureLayout
import OHHTTPStubs
import Kingfisher

@testable import MAGE

class MageServerTestsSwift: QuickSpec {
    
    override func spec() {
        
        describe("MageServerTests") {
            
            beforeEach {
                TestHelpers.clearAndSetUpStack();
            }
            
            afterEach {
                FeedService.shared.stop();
                HTTPStubs.removeAllStubs();
                TestHelpers.clearAndSetUpStack();
            }
            
            it("should request the API") {
                UserDefaults.standard.baseServerUrl = nil;
                var apiCallCount = 0;
                HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
                    return request.url == URL(string: "https://magetest/api");
                }) { (request) -> HTTPStubsResponse in
                    apiCallCount += 1;
                    print("API CALL COUNT \(apiCallCount)")
                    let stubPath = OHPathForFile("apiSuccess6.json", type(of: self))
                    return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
                };
                
                MageServer.server(with: URL(string: "https://magetest")) { (server: MageServer?) in
                    let authStrategies = UserDefaults.standard.authenticationStrategies;
                    expect(authStrategies?.count).to(equal(1));
                    expect(server?.authenticationModules.count).to(equal(1));
                } failure: { (error) in
                    print("Error \(error?.localizedDescription ?? "")")
                    expect(1).to(equal(2));
                }

                expect(apiCallCount).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.milliseconds(500), description: "API pulled");
            }
            
            // THIS CRASHES MAGE
            xit("should request the API return 200 no data") {
                UserDefaults.standard.baseServerUrl = nil;
                var apiCallCount = 0;
                HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
                    return request.url == URL(string: "https://magetest/api");
                }) { (request) -> HTTPStubsResponse in
                    apiCallCount += 1;
                    let response = HTTPStubsResponse();
                    response.statusCode = 200;
                    response.httpHeaders = ["Content-Type": "application/json"];
                    return response;
                };
                
                MageServer.server(with: URL(string: "https://magetest")) { (server: MageServer?) in
                    let authStrategies = UserDefaults.standard.authenticationStrategies;
                    expect(authStrategies?.count).to(equal(1));
                    expect(server?.authenticationModules.count).to(equal(1));
                } failure: { (error) in
                    print("Error \(error?.localizedDescription ?? "")")
                    expect(1).to(equal(2));
                }
                
                expect(apiCallCount).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.milliseconds(500), description: "API pulled");
            }

            // THIS CRASHES MAGE
            xit("should request the API html response") {
                UserDefaults.standard.baseServerUrl = nil;
                var apiCallCount = 0;
                HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
                    return request.url == URL(string: "https://magetest/api");
                }) { (request) -> HTTPStubsResponse in
                    apiCallCount += 1;
                    let stubPath = OHPathForFile("testResponse.html", type(of: self))

                    return HTTPStubsResponse.init(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "text/html"]);
                };
                
                MageServer.server(with: URL(string: "https://magetest")) { (server: MageServer?) in
                    let authStrategies = UserDefaults.standard.authenticationStrategies;
                    expect(authStrategies?.count).to(equal(1));
                    expect(server?.authenticationModules.count).to(equal(1));
                } failure: { (error) in
                    print("Error \(error?.localizedDescription ?? "")")
                    expect(1).to(equal(2));
                }
                
                expect(apiCallCount).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.milliseconds(500), description: "API pulled");
            }
            
            it("should request the API json response") {
                UserDefaults.standard.baseServerUrl = nil;
                var apiCallCount = 0;
                HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
                    return request.url == URL(string: "https://magetest/api");
                }) { (request) -> HTTPStubsResponse in
                    apiCallCount += 1;
                    let json: [String : Any] = [
                        :
                    ];
                    return HTTPStubsResponse(jsonObject: json, statusCode: 200, headers: ["Content-Type": "application/json"]);
                };
                
                MageServer.server(with: URL(string: "https://magetest")) { (server: MageServer?) in
                    let authStrategies = UserDefaults.standard.authenticationStrategies;
                    expect(authStrategies?.count).to(equal(1));
                    expect(server?.authenticationModules.count).to(equal(1));
                } failure: { (error) in
                    print("Error \(error?.localizedDescription ?? "")")
                    expect(1).to(equal(2));
                }
                
                expect(apiCallCount).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.milliseconds(500), description: "API pulled");
            }
        }
    }
}

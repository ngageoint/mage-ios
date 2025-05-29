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

class MageServerTestsSwift: MageInjectionTestCase {
            
    override func tearDown() {
        super.tearDown()
        FeedService.shared.stop();
        HTTPStubs.removeAllStubs();
        TestHelpers.clearAndSetUpStack();
    }
    
    func testShouldRequestTheAPI() {
        UserDefaults.standard.baseServerUrl = nil;
        var apiCallCount = 0;
        HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            return request.url == URL(string: "https://magetest/api");
        }) { (request) -> HTTPStubsResponse in
            apiCallCount += 1;
            let stubPath = OHPathForFile("apiSuccess6.json", type(of: self))
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        };
        
        var serverSetUp = false
        MageServer.server(url: URL(string: "https://magetest")!) { (server: MageServer?) in
            let authStrategies = UserDefaults.standard.authenticationStrategies;
            expect(authStrategies?.count).to(equal(2));
            expect(server?.authenticationModules?.count).to(equal(2));
            expect(server!.serverHasLocalAuthenticationStrategy).to(beTrue())
            let strategies: [[String: Any]] = server?.strategies ?? []
            expect(strategies.count).to(equal(2))

            // local should always be the last one in the list
            let local = strategies[strategies.count - 1]
            expect(local["identifier"] as? String).to(equal("local"))
            
            let oauth = strategies[0]
            expect(oauth["identifier"] as? String).to(equal("oauth"))
            
            let oauthStrategies: [[String: Any]] = server?.oauthStrategies ?? []
            expect(oauthStrategies.count).to(equal(1))
            let oauthAgain = oauthStrategies[0]
            expect(oauthAgain["identifier"] as? String).to(equal("oauth"))
            serverSetUp = true
        } failure: { (error) in
            XCTFail()
        }

        expect(apiCallCount).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.milliseconds(500), description: "API pulled");
        expect(serverSetUp).toEventually(beTrue())
        expect(UserDefaults.standard.contactInfoEmail).to(equal("test@nowhere"))
        expect(UserDefaults.standard.contactInfoPhone).to(equal("000-000-0000"))
        expect(UserDefaults.standard.disclaimerText).to(equal("Disclaimer text"))
        expect(UserDefaults.standard.disclaimerTitle).to(equal("Consent to Monitoring"))
        expect(UserDefaults.standard.showDisclaimer).to(beTrue())
        
        expect(MageServer.baseURL).to(equal(URL(string: "https://magetest")))
        expect(MageServer.isServerVersion5).to(beFalse())
        expect(MageServer.isServerVersion6_0).to(beTrue())
    }
    
    func testShouldSetAnInvalidUrl() {
        UserDefaults.standard.baseServerUrl = nil;

        var serverSetUp = false
        MageServer.server(url: URL(string: "notgood://magetest")!) { (server: MageServer?) in
            XCTFail()
        } failure: { (error) in
            expect(error.localizedDescription).to(contain("unsupported URL"))
            serverSetUp = true
        }
        
        expect(serverSetUp).toEventually(beTrue())
    }
    
    func testShouldSetAnInvalidURLWithNoHost() {
        UserDefaults.standard.baseServerUrl = nil;
        
        var serverSetUp = false
        MageServer.server(url: URL(string: "notgood://")!) { (server: MageServer?) in
            XCTFail()
        } failure: { (error) in
            expect(error.localizedDescription).to(contain("Invalid URL"))
            serverSetUp = true
        }
        
        expect(serverSetUp).toEventually(beTrue())
    }
    
    func testShouldRequestTheAPIAndReturnAnErrorIfNoAuthenticationStrategiesAreFound() {
        UserDefaults.standard.baseServerUrl = nil;
        var apiCallCount = 0;
        HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            return request.url == URL(string: "https://magetest/api");
        }) { (request) -> HTTPStubsResponse in
            apiCallCount += 1;
            let stubPath = OHPathForFile("apiSuccessNoAuthStrategies.json", type(of: self))
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        };
        
        MageServer.server(url: URL(string: "https://magetest")!) { (server: MageServer?) in
            XCTFail()
        } failure: { (error) in
            expect(error.localizedDescription).to(contain("Invalid response from the MAGE server."))
        }
        
        expect(apiCallCount).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.milliseconds(500), description: "API pulled");
    }
    
    func testShouldRequestTheAPIReturn200NoData() {
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
        
        MageServer.server(url: URL(string: "https://magetest")!) { (server: MageServer?) in
            XCTFail()
        } failure: { (error) in
            expect(error.localizedDescription).to(equal("Empty API response received from server."))
        }
        
        expect(apiCallCount).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.milliseconds(500), description: "API pulled");
    }

    func testShouldRequestTheAPIHTMLResponse() {
        UserDefaults.standard.baseServerUrl = nil;
        var apiCallCount = 0;
        HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            return request.url == URL(string: "https://magetest/api");
        }) { (request) -> HTTPStubsResponse in
            apiCallCount += 1;
            let stubPath = OHPathForFile("testResponse.html", type(of: self))

            return HTTPStubsResponse.init(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "text/html"]);
        };
        
        MageServer.server(url: URL(string: "https://magetest")!) { (server: MageServer?) in
            XCTFail()
        } failure: { (error) in
            expect(error.localizedDescription).to(contain("Invalid API response received from server. <html>"))
        }
        
        expect(apiCallCount).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.milliseconds(500), description: "API pulled");
    }
    
    func testShouldRequestTheAPIJsonResponse() {
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
        
        MageServer.server(url: URL(string: "https://magetest")!) { (server: MageServer?) in
            XCTFail()
        } failure: { (error) in
            expect(error.localizedDescription).to(contain("Invalid server response"))
        }
        
        expect(apiCallCount).toEventually(equal(1), timeout: DispatchTimeInterval.seconds(10), pollInterval: DispatchTimeInterval.milliseconds(500), description: "API pulled");
    }
    
    func testSetURLThatHasAlreadyBeenSetWithoutStoredPasswordOrAPIRetrievedAndNoConnectionShouldHaveNoLoginModulesAndShouldReturnAFailure() {
        UserDefaults.standard.baseServerUrl = "https://magetest";
        UserDefaults.standard.deviceRegistered = true
        
        var apiCalled = false;
        HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            return request.url == URL(string: "https://magetest/api");
        }) { (request) -> HTTPStubsResponse in
            apiCalled = true;
            return HTTPStubsResponse(error: NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil))
        };
        
        var serverSetup = false
        MageServer.server(url: URL(string: "https://magetest")!) { (server: MageServer?) in
            XCTFail()
        } failure: { (error) in
            serverSetup = true
            expect(error.localizedDescription).to(contain("The operation couldn’t be completed. (NSURLErrorDomain error -1009.)"))
        }
        
        expect(apiCalled).toEventually(beTrue())
        expect(serverSetup).toEventually(beTrue())
    }
    
    // TODO: The note below is rather concerning.
    // this is a strange test that would never happen because there would be auth modules if there was a stored password but just for completeness if we modify the way the MageServer class works..
    func testShouldReturnOfflineLoginTypeIfNetworkIsUnreachableButALoginHasOccuredInThePast() {
        StoredPassword.clear()
        UserDefaults.standard.baseServerUrl = "https://magetest";
        UserDefaults.standard.deviceRegistered = true
        UserDefaults.standard.loginParameters = [
            "serverUrl": "https://magetest"
        ]
        
        StoredPassword.persistPassword(toKeyChain: "fakepassword")
        
        var apiCalled = false
        HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            return request.url == URL(string: "https://magetest/api");
        }) { (request) -> HTTPStubsResponse in
            apiCalled = true
            return HTTPStubsResponse(error: NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet, userInfo: nil))
        };
        
        var serverSetup = false
        MageServer.server(url: URL(string: "https://magetest")!) { (server: MageServer?) in
            let localAuthenticationModule = server?.authenticationModules?["offline"]
            let serverAuthModule = server?.authenticationModules?["local"]
            expect(localAuthenticationModule).toNot(beNil())
            expect(serverAuthModule).to(beNil())
            expect(server!.serverHasLocalAuthenticationStrategy).to(beFalse())
            serverSetup = true
        } failure: { (error) in
            XCTFail()
        }
        
        expect(apiCalled).toEventually(beTrue())
        expect(serverSetup).toEventually(beTrue())
        
        StoredPassword.clear()
    }
    
    func testShouldNotReFetchTheServerAPIIfOneExistsWithAuthenticationStrategiesAlready() {
        UserDefaults.standard.baseServerUrl = "https://magetest";
        UserDefaults.standard.deviceRegistered = true
        UserDefaults.standard.authenticationStrategies = [
            "local": [
                "passwordMinLength": 14
            ]
        ]
        
        var serverSetup = false
        MageServer.server(url: URL(string: "https://magetest")!) { (server: MageServer?) in
            let localAuthenticationModule = server?.authenticationModules?["offline"]
            let serverAuthModule = server?.authenticationModules?["local"]
            expect(localAuthenticationModule).to(beNil())
            expect(serverAuthModule).toNot(beNil())
            expect(server!.serverHasLocalAuthenticationStrategy).to(beTrue())
            serverSetup = true
        } failure: { (error) in
            XCTFail()
        }
        
        expect(serverSetup).toEventually(beTrue())
    }
    
    func testShouldSetURLWithNoStoredPassword() {
        StoredPassword.clear()
        UserDefaults.standard.baseServerUrl = "https://magetest";
        UserDefaults.standard.deviceRegistered = true
        UserDefaults.standard.authenticationStrategies = [
            "local": [
                "passwordMinLength": 14
            ]
        ]
        
        var serverSetup = false
        MageServer.server(url: URL(string: "https://magetest")!) { (server: MageServer?) in
            let localAuthenticationModule = server?.authenticationModules?["offline"]
            let serverAuthModule = server?.authenticationModules?["local"]
            expect(localAuthenticationModule).to(beNil())
            expect(serverAuthModule).toNot(beNil())
            serverSetup = true
        } failure: { (error) in
            XCTFail()
        }
        
        expect(serverSetup).toEventually(beTrue())
    }
    
    func testShouldSetURLWithStoredPassword() {
        StoredPassword.clear()
        UserDefaults.standard.baseServerUrl = "https://magetest";
        UserDefaults.standard.deviceRegistered = true
        UserDefaults.standard.authenticationStrategies = [
            "local": [
                "passwordMinLength": 14
            ]
        ]
        UserDefaults.standard.loginParameters = [
            "serverUrl": "https://magetest"
        ]
        
        StoredPassword.persistPassword(toKeyChain: "fakepassword")
        
        var serverSetup = false
        MageServer.server(url: URL(string: "https://magetest")!) { (server: MageServer?) in
            let localAuthenticationModule = server?.authenticationModules?["offline"]
            let serverAuthModule = server?.authenticationModules?["local"]
            expect(localAuthenticationModule).toNot(beNil())
            expect(serverAuthModule).toNot(beNil())
            serverSetup = true
        } failure: { (error) in
            XCTFail()
        }
        
        expect(serverSetup).toEventually(beTrue())

        StoredPassword.clear()
    }
    
    func testShouldGenerateIncompatibilityError() {
        let server6 = [
            "version": [
                "major": 6,
                "minor": 0,
                "micro": 0
            ]
        ]
        
        let error: NSError = MageServer.generateServerCompatibilityError(api:server6) as NSError
        expect(error.code).to(equal(1))
        expect(error.domain).to(equal("MAGE"))
        expect(error.userInfo[NSLocalizedDescriptionKey] as? String).to(equal("This version of the app is not compatible with version 6.0.0 of the server.  Please contact your MAGE administrator for more information."))
        
        let error2: NSError = MageServer.generateServerCompatibilityError(api:[
            "test":"nope"
        ]) as NSError
        expect(error2.code).to(equal(1))
        expect(error2.domain).to(equal("MAGE"))
        expect((error2.userInfo[NSLocalizedDescriptionKey] as? String)).to(contain("Invalid server response {"))
    }
    
    func testShouldCheckServerCompatibility() {
        let server6 = [
            "version": [
                "major": 6,
                "minor": 0,
                "micro": 0
            ]
        ]
        
        let server61 = [
            "version": [
                "major": 6,
                "minor": 1,
                "micro": 0
            ]
        ]
        
        let server5 = [
            "version": [
                "major": 5,
                "minor": 4,
                "micro": 0
            ]
        ]
        
        let server53 = [
            "version": [
                "major": 5,
                "minor": 3,
                "micro": 0
            ]
        ]
        
        UserDefaults.standard.serverCompatibilities = [[
            "serverMajorVersion":6,
            "serverMinorVersion":0
        ]]
        
        expect(MageServer.checkServerCompatibility(api:server6)).to(beTrue())
        expect(MageServer.checkServerCompatibility(api:server5)).to(beFalse())
        expect(MageServer.checkServerCompatibility(api:server61)).to(beTrue())
        expect(MageServer.checkServerCompatibility(api:server53)).to(beFalse())
        
        UserDefaults.standard.serverCompatibilities = [[
            "serverMajorVersion":5,
            "serverMinorVersion":4
        ]]
        
        expect(MageServer.checkServerCompatibility(api:server6)).to(beFalse())
        expect(MageServer.checkServerCompatibility(api:server5)).to(beTrue())
        expect(MageServer.checkServerCompatibility(api:server61)).to(beFalse())
        expect(MageServer.checkServerCompatibility(api:server53)).to(beFalse())
        
        UserDefaults.standard.serverCompatibilities = [[
            "serverMajorVersion":5,
            "serverMinorVersion":4
        ],[
            "serverMajorVersion":6,
            "serverMinorVersion":0
        ]]
        
        expect(MageServer.checkServerCompatibility(api:server6)).to(beTrue())
        expect(MageServer.checkServerCompatibility(api:server5)).to(beTrue())
        expect(MageServer.checkServerCompatibility(api:server61)).to(beTrue())
        expect(MageServer.checkServerCompatibility(api:server53)).to(beFalse())
    }
    
    func testShouldSetURLHitAPIWithNoStoredPassword() {
        StoredPassword.clear()
        UserDefaults.standard.baseServerUrl = "https://magetest";
        UserDefaults.standard.deviceRegistered = true
        
        var apiCalled = false
        HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            return request.url == URL(string: "https://magetest/api");
        }) { (request) -> HTTPStubsResponse in
            apiCalled = true
            let stubPath = OHPathForFile("apiSuccess.json", type(of: self))
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        };
        
        var serverSetup = false
        MageServer.server(url: URL(string: "https://magetest")!) { (server: MageServer?) in
            let localAuthenticationModule = server?.authenticationModules?["offline"]
            let serverAuthModule = server?.authenticationModules?["local"]
            expect(localAuthenticationModule).to(beNil())
            expect(serverAuthModule).toNot(beNil())
            serverSetup = true
        } failure: { (error) in
            XCTFail()
        }
        
        expect(apiCalled).toEventually(beTrue())
        expect(serverSetup).toEventually(beTrue())
        
        expect(MageServer.isServerVersion5).to(beTrue())
        expect(MageServer.isServerVersion6_0).to(beFalse())
        
        StoredPassword.clear()
    }
    
    func testShouldSetURLWith503() {
        UserDefaults.standard.baseServerUrl = "https://magetest";
        UserDefaults.standard.deviceRegistered = true
        
        var apiCalled = false
        HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            return request.url == URL(string: "https://magetest/api");
        }) { (request) -> HTTPStubsResponse in
            apiCalled = true
            let response = HTTPStubsResponse()
            response.statusCode = 503
            return response
        };
        
        var serverSetup = false
        MageServer.server(url: URL(string: "https://magetest")!) { (server: MageServer?) in
            XCTFail()
        } failure: { (error) in
            expect(error.localizedDescription).to(contain("Request failed: service unavailable (503)"))
            serverSetup = true
        }
        
        expect(apiCalled).toEventually(beTrue())
        expect(serverSetup).toEventually(beTrue())
    }
    
    func testShouldSetURLHitAPIWithStoredPassword() {
        StoredPassword.clear()
        UserDefaults.standard.baseServerUrl = "https://magetest";
        UserDefaults.standard.deviceRegistered = true
        UserDefaults.standard.loginParameters = [
            "serverUrl": "https://magetest"
        ]
        StoredPassword.persistPassword(toKeyChain: "fakepassword")

        var apiCalled = false
        HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            return request.url == URL(string: "https://magetest/api");
        }) { (request) -> HTTPStubsResponse in
            apiCalled = true
            let stubPath = OHPathForFile("apiSuccess.json", type(of: self))
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        };
        
        var serverSetup = false
        MageServer.server(url: URL(string: "https://magetest")!) { (server: MageServer?) in
            let localAuthenticationModule = server?.authenticationModules?["offline"]
            let serverAuthModule = server?.authenticationModules?["local"]
            expect(localAuthenticationModule).toNot(beNil())
            expect(serverAuthModule).toNot(beNil())
            serverSetup = true
        } failure: { (error) in
            XCTFail()
        }
        
        expect(apiCalled).toEventually(beTrue())
        expect(serverSetup).toEventually(beTrue())
        
        StoredPassword.clear()
    }
    
    func testShouldFailWithNonMAGEAPIJSONIsReturned() {
        UserDefaults.standard.baseServerUrl = "https://magetest";
        
        var apiCalled = false
        HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            return request.url == URL(string: "https://magetest/api");
        }) { (request) -> HTTPStubsResponse in
            apiCalled = true
            let stubPath = OHPathForFile("registrationSuccess.json", type(of: self))
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        };
        
        var serverSetup = false
        MageServer.server(url: URL(string: "https://magetest")!) { (server: MageServer?) in
            XCTFail()
        } failure: { (error) in
            expect(error.localizedDescription).to(contain("Invalid server response {"))
            serverSetup = true
        }
        
        expect(apiCalled).toEventually(beTrue())
        expect(serverSetup).toEventually(beTrue())
    }
    
    // TODO: FLAKY TESTS DUE TO 'test_marker.png' issues.
    /// failed - Stub file does not exist at path: /Users/brent/Library/Developer/XCTestDevices/619FC9DB-7015-4E9B-A4AD-E5B19E32B287/data/Containers/Bundle/Application/256A7AD8-4804-44BB-B9BC-F0C4891AAB80/MAGE.app/PlugIns/MAGETests.xctest/test_marker.png
    func testShouldFailWhenAnImageIsrReturned() {
        let fileName = "test_marker.png"
        UserDefaults.standard.baseServerUrl = "https://magetest";
        
        guard let filePath = Bundle(for: type(of: self)).path(forResource: fileName, ofType: nil) else {
            return
        }

        guard FileManager.default.fileExists(atPath: filePath) else {
            return
        }

        var apiCalled = false
        HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            return request.url == URL(string: "https://magetest/api");
        }) { (request) -> HTTPStubsResponse in
            apiCalled = true
            let stubPath = OHPathForFile(fileName, type(of: self))
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "image/png"]);
        };
        
        var serverSetup = false
        MageServer.server(url: URL(string: "https://magetest")!) { (server: MageServer?) in
            XCTFail()
        } failure: { (error) in
            expect(error.localizedDescription).to(contain("Unknown API response received from server."))
            serverSetup = true
        }
        
        expect(apiCalled).toEventually(beTrue())
        expect(serverSetup).toEventually(beTrue())
    }
    
    func testShouldFailWhenNoDataIsReturned() {
        UserDefaults.standard.baseServerUrl = "https://magetest";
        
        var apiCalled = false
        HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            return request.url == URL(string: "https://magetest/api");
        }) { (request) -> HTTPStubsResponse in
            apiCalled = true
            let response = HTTPStubsResponse()
            response.httpHeaders = ["Content-Type": "application/json"]
            response.statusCode = 200
            return response
        };
        
        var serverSetup = false
        MageServer.server(url: URL(string: "https://magetest")!) { (server: MageServer?) in
            XCTFail()
        } failure: { (error) in
            expect(error.localizedDescription).to(contain("Empty API response received from server."))
            serverSetup = true
        }
        
        expect(apiCalled).toEventually(beTrue())
        expect(serverSetup).toEventually(beTrue())
    }
}

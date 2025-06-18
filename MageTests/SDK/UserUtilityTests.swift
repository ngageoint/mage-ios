//
//  UserUtilityTests.swift
//  MAGETests
//
//  Created by Daniel Barela on 11/12/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Quick
import Nimble
import OHHTTPStubs

@testable import MAGE

class UserUtilityTests: KIFSpec {
    
    override func spec() {
        
        describe("UserUtility Tests") {
            
            beforeEach {
                TestHelpers.resetUserDefaults();
                UserUtility.singleton.resetExpiration()
            }
            
            afterEach {
                TestHelpers.resetUserDefaults();
                UserUtility.singleton.resetExpiration()
            }
            
            it("should get an expired token because nothing has been set") {
                UserDefaults.standard.removeObject(forKey: "loginParameters")
                expect(UserUtility.singleton.isTokenExpired).to(beTrue());
            }
            
            it("should get an expired token because the token expiration date is too old") {
                UserDefaults.standard.loginParameters = [
                    LoginParametersKey.acceptedConsent.key: LoginParametersKey.agree.key,
                    LoginParametersKey.tokenExpirationDate.key: Date().addingTimeInterval(-10000)
                ]
                expect(UserUtility.singleton.isTokenExpired).to(beTrue());
            }
            
            it("should get an expired token because the consent is not accepted") {
                UserDefaults.standard.loginParameters = [
                    LoginParametersKey.tokenExpirationDate.key: Date().addingTimeInterval(1000000)
                ]
                expect(UserUtility.singleton.isTokenExpired).to(beTrue());
            }
            
            it("should get an expired token because the consent is not set to agree") {
                UserDefaults.standard.loginParameters = [
                    LoginParametersKey.acceptedConsent.key: "turtle",
                    LoginParametersKey.tokenExpirationDate.key: Date().addingTimeInterval(1000000)
                ]
                expect(UserUtility.singleton.isTokenExpired).to(beTrue());
            }
            
            it("should not have an expired token after acceptConsent is called") {
                UserDefaults.standard.loginParameters = [
                    LoginParametersKey.tokenExpirationDate.key: Date().addingTimeInterval(1000000)
                ]
                expect(UserUtility.singleton.isTokenExpired).to(beTrue());
                UserUtility.singleton.resetExpiration()
                UserUtility.singleton.acceptConsent()
                expect(UserUtility.singleton.isTokenExpired).to(beFalse());
            }
            
            it("should have an expired token after expireToken is called") {
                UserDefaults.standard.loginParameters = [
                    LoginParametersKey.tokenExpirationDate.key: Date().addingTimeInterval(1000000)
                ]
                expect(UserUtility.singleton.isTokenExpired).to(beTrue());
                UserUtility.singleton.resetExpiration()
                UserUtility.singleton.acceptConsent()
                expect(UserUtility.singleton.isTokenExpired).to(beFalse());
                UserUtility.singleton.expireToken();
                expect(UserUtility.singleton.isTokenExpired).to(beTrue());
            }
            
            it("should not have an expired token if all parameters are set properly") {
                UserDefaults.standard.loginParameters = [
                    LoginParametersKey.acceptedConsent.key: LoginParametersKey.agree.key,
                    LoginParametersKey.tokenExpirationDate.key: Date().addingTimeInterval(1000000)
                ]
                expect(UserUtility.singleton.isTokenExpired).to(beFalse());
            }
            
            it("should expire the token when logout is called") {
                UserDefaults.standard.loginParameters = [
                    LoginParametersKey.acceptedConsent.key: LoginParametersKey.agree.key,
                    LoginParametersKey.tokenExpirationDate.key: Date().addingTimeInterval(1000000)
                ]
                expect(UserUtility.singleton.isTokenExpired).to(beFalse());
                
                var stubCalled = false;
                UserDefaults.standard.baseServerUrl = "https://magetest";

                stub(condition: isMethodPOST() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/logout")
                ) { (request) -> HTTPStubsResponse in
                    let response: [String: Any] = [ : ];
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: response, statusCode: 200, headers: nil);
                }
                
                var logoutCompletionCalled = false;
                UserUtility.singleton.logout {
                    logoutCompletionCalled = true;
                }
                
                expect(stubCalled).toEventually(beTrue());
                expect(logoutCompletionCalled).toEventually(beTrue());
                
                expect(UserUtility.singleton.isTokenExpired).to(beTrue());
            }
            
            it("should expire the token when logout is called even if a failure occurs") {
                UserDefaults.standard.loginParameters = [
                    LoginParametersKey.acceptedConsent.key: LoginParametersKey.agree.key,
                    LoginParametersKey.tokenExpirationDate.key: Date().addingTimeInterval(1000000)
                ]
                expect(UserUtility.singleton.isTokenExpired).to(beFalse());
                
                var stubCalled = false;
                UserDefaults.standard.baseServerUrl = "https://magetest";
                
                stub(condition: isMethodPOST() &&
                     isHost("magetest") &&
                     isScheme("https") &&
                     isPath("/api/logout")
                ) { (request) -> HTTPStubsResponse in
                    let response: [String: Any] = [ : ];
                    stubCalled = true;
                    return HTTPStubsResponse(jsonObject: response, statusCode: 503, headers: nil);
                }
                
                var logoutCompletionCalled = false;
                UserUtility.singleton.logout {
                    logoutCompletionCalled = true;
                }
                
                expect(stubCalled).toEventually(beTrue());
                expect(logoutCompletionCalled).toEventually(beTrue());
                
                expect(UserUtility.singleton.isTokenExpired).to(beTrue());
            }
        }
    }
}

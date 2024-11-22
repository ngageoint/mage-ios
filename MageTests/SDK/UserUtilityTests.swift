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
import Testing

@testable import MAGE

// TODO: This might be a good place to start with Swift Testing
class UserUtilityTests: XCTestCase {
    
    override func setUp() {
        TestHelpers.resetUserDefaults();
        UserUtility.singleton.resetExpiration()
    }
    
    override func tearDown() {
        TestHelpers.resetUserDefaults();
        UserUtility.singleton.resetExpiration()
    }
    
    func testShouldGetAnExpiredTokenBecauseNothingHasBeenSet() {
        UserDefaults.standard.removeObject(forKey: "loginParameters")
        expect(UserUtility.singleton.isTokenExpired).to(beTrue());
    }
    
    func testShouldGetAnExpiredTokenBecauseTheTokenExpirationDateIsTooOld() {
        UserDefaults.standard.loginParameters = [
            LoginParametersKey.acceptedConsent.key: LoginParametersKey.agree.key,
            LoginParametersKey.tokenExpirationDate.key: Date().addingTimeInterval(-10000)
        ]
        expect(UserUtility.singleton.isTokenExpired).to(beTrue());
    }
    
    func testShouldGetAnExpiredTokenBecauseTheConsentIsNotAccepted() {
        UserDefaults.standard.loginParameters = [
            LoginParametersKey.tokenExpirationDate.key: Date().addingTimeInterval(1000000)
        ]
        expect(UserUtility.singleton.isTokenExpired).to(beTrue());
    }
    
    func testShouldGetAnExpiredTokenBecauseTheConsentIsNotSetToAgree() {
        UserDefaults.standard.loginParameters = [
            LoginParametersKey.acceptedConsent.key: "turtle",
            LoginParametersKey.tokenExpirationDate.key: Date().addingTimeInterval(1000000)
        ]
        expect(UserUtility.singleton.isTokenExpired).to(beTrue());
    }
    
    func testShouldNotHaveAnExpiredTokenAfterAcceptConsentIsCalled() {
        UserDefaults.standard.loginParameters = [
            LoginParametersKey.tokenExpirationDate.key: Date().addingTimeInterval(1000000)
        ]
        expect(UserUtility.singleton.isTokenExpired).to(beTrue());
        UserUtility.singleton.resetExpiration()
        UserUtility.singleton.acceptConsent()
        expect(UserUtility.singleton.isTokenExpired).to(beFalse());
    }
    
    func testShouldHaveAnExpiredTokenAfterExpireTokenIsCalled() {
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
    
    func testShouldNotHaveAnExpiredTokenIfAllParametersAreSetProperly() {
        UserDefaults.standard.loginParameters = [
            LoginParametersKey.acceptedConsent.key: LoginParametersKey.agree.key,
            LoginParametersKey.tokenExpirationDate.key: Date().addingTimeInterval(1000000)
        ]
        expect(UserUtility.singleton.isTokenExpired).to(beFalse());
    }
    
    func testShouldExpireTheTokenWhenLogoutIsCalled() {
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
    
    func testShouldExpireTheTokenWhenLogoutIsCalledEvenIfAFailureOccurs() {
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

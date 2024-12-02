//
//  UserRemoteDataSourceTests.swift
//  MAGETests
//
//  Created by Dan Barela on 9/3/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Combine
import Nimble
import OHHTTPStubs

@testable import MAGE

final class UserRemoteDataSourceTests: XCTestCase {
    
    var cancellables: Set<AnyCancellable> = Set()
    
    override func setUp() {
        UserDefaults.standard.baseServerUrl = "https://magetest"

    }
    
    override func tearDown() {
        HTTPStubs.removeAllStubs()
    }
    
    func testGetCurrentUser() async {
        MageSessionManager.shared().setToken("NewToken")
        UserDefaults.standard.loginParameters = [
            LoginParametersKey.acceptedConsent.key: LoginParametersKey.agree.key,
            LoginParametersKey.tokenExpirationDate.key: Date().addingTimeInterval(1000000)
        ]
        UserUtility.singleton.resetExpiration()
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/users/myself")
        ) { (request) -> HTTPStubsResponse in
            let stubPath = OHPathForFile("myself.json", MageTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        let remoteDataSource = UserRemoteDataSourceImpl()
        let response = await remoteDataSource.fetchMyself()
        
        XCTAssertEqual(response!["id"] as? String, "userabc")
    }
    
    func testGetCurrentUserTokenExpired() async {
        MageSessionManager.shared().setToken("NewToken")
        UserDefaults.standard.loginParameters = [
            LoginParametersKey.acceptedConsent.key: LoginParametersKey.agree.key,
            LoginParametersKey.tokenExpirationDate.key: Date().addingTimeInterval(-1000000)
        ]
        stub(condition: isMethodGET() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/api/users/myself")
        ) { (request) -> HTTPStubsResponse in
            let stubPath = OHPathForFile("myself.json", MageTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
        let remoteDataSource = UserRemoteDataSourceImpl()
        let response = await remoteDataSource.fetchMyself()
        
        XCTAssertNil(response)
    }
}

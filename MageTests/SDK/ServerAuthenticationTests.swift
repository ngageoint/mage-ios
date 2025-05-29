//
//  ServerAuthenticationTests.swift
//  MAGETests
//
//  Created by Dan Barela on 11/13/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import OHHTTPStubs

@testable import MAGE

final class ServerAuthenticationTests: AsyncMageCoreDataTestCase {
    
    override func setUp() async throws {
        try await super.setUp()
        UserDefaults.standard.baseServerUrl = "https://magetest";
        UserDefaults.standard.serverMajorVersion = 6;
        UserDefaults.standard.serverMinorVersion = 0;
        
    }

    func testLoginWithParameters() {
        
        let parameters: [String: Any] = [
            "strategy" : [
                "local": [
                  "enabled": true,
                  "lastUpdated": "2024-11-05T15:13:28.203Z",
                  "settings": [
                    "passwordPolicy": [
                      "passwordHistoryCountEnabled": false,
                      "passwordHistoryCount": 15,
                      "helpTextTemplate": [
                        "passwordHistoryCount": "not be any of the past # previous passwords",
                        "passwordMinLength": "be at least # characters in length",
                        "restrictSpecialChars": "be restricted to these special characters: #",
                        "specialChars": "have at least # special characters",
                        "numbers": "have at least # numbers",
                        "highLetters": "have a minimum of # uppercase letters",
                        "lowLetters": "have a minimum of # lowercase letters",
                        "maxConChars": "not contain more than # consecutive letters",
                        "minChars": "have at least # letters"
                      ],
                      "helpText": "Password is invalid, must be at least 14 characters in length.",
                      "customizeHelpText": true,
                      "passwordMinLengthEnabled": true,
                      "passwordMinLength": 14,
                      "restrictSpecialChars": "",
                      "restrictSpecialCharsEnabled": false,
                      "specialChars": 7,
                      "specialCharsEnabled": false,
                      "numbers": 6,
                      "numbersEnabled": false,
                      "highLetters": 5,
                      "highLettersEnabled": false,
                      "lowLetters": 4,
                      "lowLettersEnabled": false,
                      "maxConChars": 3,
                      "maxConCharsEnabled": false,
                      "minChars": 2,
                      "minCharsEnabled": false
                    ],
                    "accountLock": [
                      "enabled": true,
                      "threshold": 5,
                      "interval": 120,
                      "max": 60
                    ],
                    "devicesReqAdmin": [
                      "enabled": true
                    ],
                    "usersReqAdmin": [
                      "enabled": true
                    ],
                    "newUserTeams": [],
                    "newUserEvents": []
                  ],
                  "icon": nil,
                  "buttonColor": nil,
                  "textColor": nil,
                  "title": "MAGE Username/Password",
                  "type": "local",
                  "name": "local",
                  "_id": "serverid"
                ]
            ],
            "username": "testuser",
            "password": "testpwd"
        ]
        
        let signinStubCalled = XCTestExpectation(description: "signin called")
        
        stub(condition: isMethodPOST() &&
             isHost("magetest") &&
             isScheme("https") &&
             isPath("/auth/local/signin")
        ) { (request) -> HTTPStubsResponse in
            signinStubCalled.fulfill()
            let stubPath = OHPathForFile("attachmentPushTestResponse.json", ObservationPushServiceTests.self);
            return HTTPStubsResponse(fileAtPath: stubPath!, statusCode: 200, headers: ["Content-Type": "application/json"]);
        }
        
    }

}

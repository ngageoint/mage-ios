//
//  AuthModels.swift
//  Authentication
//
//  Created by Brent Michalski on 10/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

enum IDPProvider: Equatable { case oidc, saml, custom(name: String) }
enum AuthStrategy: Equatable { case local, idp(IDPProvider) }

struct AuthCredantials: Equatable {
    let username: String, password: String
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

struct AuthSession: Equatable {
    let token: String, userId: String
    init (token: String, userId: String) {
        self.token = token
        self.userId = userId
    }
}

struct Captcha: Equatable {
    let token: String
    let imageData: Data?
    init(token: String, imageData: Data?) {
        self.token = token
        self.imageData = imageData
    }
}

struct CaptchaVerification: Equatable {
    let isValid: Bool
    init(isValid: Bool) { self.isValid = isValid }
}


struct SignupRequest: Equatable {
    let displayName: String, username: String, password: String, email: String?
    init(displayName: String, username: String, password: String, email: String?) {
        self.displayName = displayName
        self.username = username
        self.password = password
        self.email = email
    }
}

struct SignupResult: Equatable {
    let userId: String
     init(userId: String) { self.userId = userId }
}


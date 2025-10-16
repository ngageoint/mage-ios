//
//  AuthModels.swift
//  Authentication
//
//  Created by Brent Michalski on 10/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public enum IDPProvider: Equatable { case oidc, saml, custom(name: String) }
public enum AuthStrategy: Equatable { case local, idp(IDPProvider) }

public struct AuthCredantials: Equatable {
    public let username: String, password: String
    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

public struct AuthSession: Equatable {
    public let token: String, userId: String
    public init (token: String, userId: String) {
        self.token = token
        self.userId = userId
    }
}

public struct Captcha: Equatable {
    public let token: String
    public let imageData: Data?
    public init(token: String, imageData: Data?) {
        self.token = token
        self.imageData = imageData
    }
}

public struct CaptchaVerification: Equatable {
    public let isValid: Bool
    public init(isValid: Bool) { self.isValid = isValid }
}


public struct SignupRequest: Equatable {
    public let displayName: String, username: String, password: String, email: String?
    public init(displayName: String, username: String, password: String, email: String?) {
        self.displayName = displayName
        self.username = username
        self.password = password
        self.email = email
    }
}

public struct SignupResult: Equatable {
    public let userId: String
    public init(userId: String) { self.userId = userId }
}


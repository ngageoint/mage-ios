//
//  AuthService.swift
//  MAGE
//
//  Created by Brent Michalski on 9/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public protocol AuthService {
    func fetchSignupCaptcha(username: String, backgroundHex: String) async throws -> SignupCaptcha
    func submitSignup(_ request: SignupRequest, captchaText: String, token: String) async throws -> SignupVerificationResponse
    func changePassword(_ req: ChangePasswordRequest) async throws
}

public struct ServerConfig: Sendable, Equatable { public init() {} }

public struct AuthSession: Sendable, Equatable {
    public init(token: String) { self.token = token }
    public let token: String
}

public struct SignupVerificationResponse: Decodable {
    public let username: String
    public let displayNeme: String
    public let active: Bool?
}

public struct SignupRequest: Sendable, Equatable {
    public var displayName: String
    public var username: String
    public var email: String
    public var password: String
    public var confirmPassword: String
    
    public init(displayName: String = "", username: String = "", email: String = "", password: String = "", confirmPassword: String = "") {
        self.displayName = displayName
        self.username = username
        self.email = email
        self.password = password
        self.confirmPassword = confirmPassword
    }
    
    public var parameters: [String: Any] {
        [
            "displayName": displayName,
            "username": username,
            "email": email,
            "password": password,
            "confirmPassword": confirmPassword
        ]
    }
}

public struct ChangePasswordRequest: Sendable, Equatable {
    public var currentPassword: String
    public var newPassword: String
    public var confirmNewPassword: String
    
    public init(currentPassword: String = "", newPassword: String = "", confirmNewPassword: String = "") {
        self.currentPassword = currentPassword
        self.newPassword = newPassword
        self.confirmNewPassword = confirmNewPassword
    }
}


public protocol SessionStore: Sendable {
    var current: AuthSession? { get }
    func set(_ session: AuthSession?) async
    func clear() async
}

public struct SignupCaptcha: Sendable, Equatable {
    public var token: String
    public var imageBase64: String
    
    public init(token: String, imageBase64: String) {
        self.token = token
        self.imageBase64 = imageBase64
    }
}


//
//  AuthService.swift
//  MAGE
//
//  Created by Brent Michalski on 9/4/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public struct ServerConfig: Sendable, Equatable { public init() {} }
public struct AuthSession: Sendable, Equatable {
    public init(token: String) { self.token = token }
    public let token: String
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

public enum AuthError: Error, Equatable {
    case invalidInput(String)
    case network
    case unauthorized
    case rateLimited
    case server(String)
}

public protocol AuthService {
    func signup(_ req: SignupRequest) async throws -> AuthSession
    func changePassword(_ req: ChangePasswordRequest) async throws
}

public protocol SessionStore: Sendable {
    var current: AuthSession? { get }
    func set(_ session: AuthSession?) async
    func clear() async
}

public final class AuthDependencies {
    public static let shared = AuthDependencies()
    public var authService: AuthService!
}

public final class SessionStoreDependencies {
    public static let shared = SessionStoreDependencies()
    public var sessionStore: SessionStore!
}

//
//  LoginViewModel.swift
//  MAGE
//
//  Created by Brent Michalski on 7/23/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Authentication
import OSLog


public enum A11yID {
    public static let loginUsername = "login.usernameField"
    public static let loginPassword = "login.passwordField"
    public static let loginSignIn   = "login.signInButton"
}

@MainActor
@objc public class LoginViewModel: NSObject, ObservableObject {
    @Published @objc public dynamic var username: String = ""
    @Published @objc public dynamic var password: String = ""
    @Published @objc public dynamic var showPassword: Bool = false
    @Published @objc public dynamic var isLoading: Bool = false
    @Published @objc public dynamic var errorMessage: String? = nil
    
    public let strategy: [String: Any]
    public let user: User?
    @objc public weak var delegate: LoginDelegate?
    
    public var userExists: Bool { user != nil }
    
    let usernamePlaceholder = "Username"
    let passwordPlaceholder = "Password"
    
    public var strategyName: String? {
        (strategy["strategy"] as? [String: Any])?["name"] as? String
    }
    
    public var strategyTitle: String? {
        (strategy["strategy"] as? [String: Any])?["title"] as? String
    }
    
    public var strategyType: String? {
        (strategy["strategy"] as? [String: Any])?["type"] as? String
    }
    
    private var loginTimeoutTask: Task<Void, Never>?
    
    // MARK: - Init
    @objc public init(strategy: [String: Any], delegate: LoginDelegate?, user: User? = nil) {
        self.strategy = strategy
        self.delegate = delegate
        self.user = user
        super.init()
        
        if let user {
            self.username = user.username ?? ""
        }
        
        if let title = (strategy["strategy"] as? [String: Any])?["title"] as? String {
            print(title)
        }
    }
    
    private func isSuccess(_ status: AuthenticationStatus) -> Bool {
        switch status {
        case .success, .registrationSuccess, .accountCreationSuccess:
            return true
        default:
            return false
        }
    }
    
    private func onceOnMain(_ original: @escaping (AuthenticationStatus, String?) -> Void) -> (AuthenticationStatus, String?) -> Void {
        var called = false
        
        return { [weak self] status, message in
            guard !called else { return }
            called = true
            Task { @MainActor in
                self?.loginTimeoutTask?.cancel()
                original(status, message)
            }
        }
    }
    
    @objc public func loginTapped() {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Username and password are required."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        loginTimeoutTask?.cancel()
        loginTimeoutTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            guard let self, !Task.isCancelled, self.isLoading else { return }
            self.isLoading = false
            self.errorMessage = "Login timed out. Please try again."
            Logger().error("Login timed out (no completion).")
        }
        
        let deviceUUID = DeviceUUID.retrieveDeviceUUID()?.uuidString ?? ""
        let infoDict = Bundle.main.infoDictionary
        let appVersion = infoDict?["CFBundleShortVersionString"] as? String ?? ""
        let buildNumber = infoDict?["CFBundleVersion"] as? String ?? ""
        let appVersionFull = "\(appVersion)-\(buildNumber)"
        
        var parameters: [String: Any] = [
            "username": username,
            "password": password,
            "uid": deviceUUID,
            "appVersion": appVersionFull
        ]
        
        if let payload = strategy["strategy"] as? [String: Any],
           let realm = payload["realm"] { parameters["realm"] = realm }
        
        let identifier = (strategy["identifier"] as? String) ?? "local"
        MageLogger.misc.debug("\n\nBBB Login Strategy Identifier: \(self.strategy["identifier"] as? String ?? "")\n\n")
        
        delegate?.login(
            withParameters: parameters as NSDictionary,
            withAuthenticationStrategy: identifier,
            complete: onceOnMain { [weak self] status, errorString in
                
                guard let self else { return }
                self.isLoading = false
                
                if self.isSuccess(status) {
                    self.username = ""
                    self.password = ""
                    self.errorMessage = nil
                    MageLogger.auth.debug("Login completed: SUCCESS")
                    // The coordinator should advance the flow after success.
                } else {
                    switch status {
                    case .unableToAuthenticate:
                        self.errorMessage = errorString ?? "Invalid username or password."
                    case .error:
                        self.errorMessage = errorString ?? "Login failed."
                    default:
                        self.errorMessage = errorString ?? "Login failed."
                    }
                    MageLogger.auth.error("Login finished with status \(String(describing: status)) : \(self.errorMessage ?? "unknown")")
                }
            }
        )
    }
    
    @objc public func signupTapped() {
        delegate?.createAccount()
    }
}

//
//  LoginViewModel.swift
//  MAGE
//
//  Created by Brent Michalski on 7/23/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

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
    
    @objc public func loginTapped() {
        guard !username.isEmpty, !password.isEmpty else {
            errorMessage = "Username and password are required."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let deviceUUID = DeviceUUID.retrieveDeviceUUID()
        let uidString = deviceUUID?.uuidString
        let infoDict = Bundle.main.infoDictionary
        let appVersion = infoDict?["CFBundleShortVersionString"] as? String ?? ""
        let buildNumber = infoDict?["CFBundleVersion"] as? String ?? ""
        let appVersionFull = "\(appVersion)-\(buildNumber)"
        
        let parameters: [String: Any] = [
            "username": username,
            "password": password,
            "strategy": strategy,
            "uid": uidString ?? "",
            "appVersion": appVersionFull
        ]
        
        MageLogger.misc.debug("\n\nBBB Login Strategy Identifier: \(self.strategy["identifier"] as? String ?? "")\n\n")
        
        delegate?.login(
            withParameters: parameters,
            withAuthenticationStrategy: strategy["identifier"] as? String ?? ""
        ) { [weak self] status, errorString in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if status == .success {
                    self?.username = ""
                    self?.password = ""
                } else {
                    self?.errorMessage = errorString
                }
            }
        }
    }
    
    @objc public func signupTapped() {
        delegate?.createAccount()
    }
}

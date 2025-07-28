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
    @objc public weak var delegate: LoginDelegate?
    
    @objc public dynamic var userExists: Bool = false
    
    @objc public init(strategy: [String: Any], delegate: LoginDelegate?, user: User? = nil) {
        self.strategy = strategy
        self.delegate = delegate
        super.init()
        
        if let user {
            self.username = user.username ?? ""
            self.userExists = true
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
        
        delegate?.login(withParameters: parameters, withAuthenticationStrategy: strategy["identifier"] as? String ?? "") { [weak self] status, errorString in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if status == .AUTHENTICATION_SUCCESS {
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

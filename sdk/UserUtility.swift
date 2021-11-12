//
//  UserUtility.m
//  mage-ios-sdk
//
//

import Foundation

@objc public class UserUtility: NSObject {
    
    var expired: Bool = false;
    
    @objc public static let singleton = UserUtility()
    
    private override init() {
        expired = false;
    }
    
    @objc public var isTokenExpired: Bool {
        get {
            if expired {
                return true;
            }
            let loginParameters = UserDefaults.standard.loginParameters
            
            if let loginParameters = loginParameters,
               let acceptedConsent = loginParameters[LoginParametersKey.acceptedConsent.key] as? String,
               let tokenExpirationDate = loginParameters[LoginParametersKey.tokenExpirationDate.key] as? Date,
               acceptedConsent == "agree" {
                let currentDate = Date();
                NSLog("current date \(currentDate) token expiration \(tokenExpirationDate)")
                expired = currentDate > tokenExpirationDate;
                if expired {
                    self.expireToken()
                    NotificationCenter.default.post(name: .MAGETokenExpiredNotification, object: nil);
                }
                return expired;
            }
            expired = true;
            return expired
        }
    }
    
    @objc public func expireToken() {
        StoredPassword.clearToken()
        var loginParameters = UserDefaults.standard.loginParameters ?? [:]
        loginParameters.removeValue(forKey: LoginParametersKey.tokenExpirationDate.key)
        loginParameters.removeValue(forKey: LoginParametersKey.acceptedConsent.key)
        
        MageSessionManager.shared().clearToken();
        
        UserDefaults.standard.loginParameters = loginParameters;
        UserDefaults.standard.loginType = nil;
        
        self.expired = true;
    }
    
    @objc public func resetExpiration() {
        self.expired = false;
    }
    
    @objc public func acceptConsent() {
        var loginParameters = UserDefaults.standard.loginParameters ?? [:];
        loginParameters[LoginParametersKey.acceptedConsent.key] = LoginParametersKey.agree.key
        UserDefaults.standard.loginParameters = loginParameters;
    }
    
    @objc public func logout(completion: @escaping () -> Void) {
        guard let baseUrl = MageServer.baseURL() else {
            completion()
            return;
        }
        let url = "\(baseUrl)/api/logout"
        
        let manager = MageSessionManager.shared();
        
        let task = manager?.post_TASK(url, parameters: nil, progress: nil, success: { task, response in
            NSLog("Logged out");
            self.expireToken()
            completion();
        }, failure: { task, error in
            NSLog("Error \(error)")
            self.expireToken()
            completion()
        })
        manager?.addTask(task);
    }
}

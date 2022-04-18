//
//  MageServer.m
//  mage-ios-sdk
//
//

import Foundation

@objc class MageServer: NSObject {
    
    static let kServerCompatibilitiesKey = "serverCompatibilities"
    static let kServerMajorVersionKey = "serverMajorVersion"
    static let kServerMinorVersionKey = "serverMinorVersion"
    static let kServerAuthenticationStrategiesKey = "serverAuthenticationStrategies"
    
    @objc public var authenticationModules: [AnyHashable: Any]?
    
    @objc public static func baseURL() -> URL? {
        if let baseServerUrl = UserDefaults.standard.baseServerUrl {
            return URL(string: baseServerUrl)
        }
        return nil
    }
    
    @objc public var serverHasLocalAuthenticationStrategy: Bool {
        get {
            if let strategies = UserDefaults.standard.serverAuthenticationStrategies, strategies["local"] != nil {
                return true
            }
            return false
        }
    }
    
    @objc public static var isServerVersion5: Bool {
        get {
            return UserDefaults.standard.serverMajorVersion == 5
        }
    }
    
    @objc public static var isServerVersion6_0: Bool {
        get {
            return UserDefaults.standard.serverMajorVersion == 6 && UserDefaults.standard.serverMinorVersion == 0
        }
    }
    
    @objc public var oauthStrategies: [[String: Any]] {
        get {
            var _oauthStrategies:[[String: Any]] = []
            if let strategies = UserDefaults.standard.serverAuthenticationStrategies {
                strategies.forEach { key, strategy in
                    if strategy["type"] as? String == "oauth2" {
                        _oauthStrategies.append(["identifier": key, "strategy": strategy])
                    }
                }
                
            }
            return _oauthStrategies
        }
    }
    
    @objc public var strategies: [[String: Any]]? {
        get {
            var _strategies: [[String: Any]] = []
            if let defaultStrategies = UserDefaults.standard.serverAuthenticationStrategies {
                defaultStrategies.forEach { key, strategy in
                    if key == "local" {
                        _strategies.append(["identifier": key, "strategy": strategy])
                    } else {
                        _strategies.insert(["identifier": key, "strategy": strategy], at: 0)
                    }
                }
                
            }
            return _strategies
        }
    }
    
    @objc public static func checkServerCompatibility(api: [AnyHashable: Any]?) -> Bool {
        guard let serverCompatibilities = UserDefaults.standard.serverCompatibilities,
              let api = api,
              let apiVersion = api["version"] as? [AnyHashable: Any],
              let serverMajorVersion = apiVersion["major"] as? Int,
              let serverMinorVersion = apiVersion["minor"] as? Int else {
            return false
        }
        
        for compatibility in serverCompatibilities {
            if let serverCompatibilityMajorVersion = compatibility[MageServer.kServerMajorVersionKey],
               let serverCompatibilityMinorVersion = compatibility[kServerMinorVersionKey],
               serverCompatibilityMajorVersion == serverMajorVersion,
               serverCompatibilityMinorVersion <= serverMinorVersion
            {
                // server is compatible, save the version
                UserDefaults.standard.serverMajorVersion = serverMajorVersion
                UserDefaults.standard.serverMinorVersion = serverMinorVersion
                return true
            }
        }
        return false
    }
    
    @objc public static func generateServerCompatibilityError(api: [AnyHashable: Any]?) -> NSError {
        if let api = api,
           let apiVersion = api["version"] as? [AnyHashable: Any],
           let serverMajorVersion = apiVersion["major"] as? Int,
           let serverMinorVersion = apiVersion["minor"] as? Int,
           let serverMicroVersion = apiVersion["micro"] as? Int
        {
            return NSError(domain: "MAGE", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "This version of the app is not compatible with version \(serverMajorVersion).\(serverMinorVersion).\(serverMicroVersion) of the server.  Please contact your MAGE administrator for more information."
            ])
        }
        if let api = api,
           let prettyApi = String(data: try! JSONSerialization.data(withJSONObject: api, options: .prettyPrinted), encoding: .utf8 )
        {
            return NSError(domain: "MAGE", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "Invalid server response \(prettyApi)"
            ])
        }
        return NSError(domain: "MAGE", code: 1, userInfo: [
            NSLocalizedDescriptionKey: "Invalid server response"
        ])
    }
    
    @objc public static func server(url: URL?, success: ((MageServer) -> Void)?, failure: ((NSError) -> Void)?) {
        guard let url = url, url.scheme != nil, url.host != nil else {
            failure?(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        let server = MageServer(url: url);
        // TODO: we need a way to force re-fetch the api in case strategies changed
        if (url.absoluteString == UserDefaults.standard.baseServerUrl && server.authenticationModules != nil) {
            success?(server)
            return
        }
        
        let manager = MageSessionManager.shared()
        let apiURL = "\(url.absoluteString)/api"
        let task = manager?.get_TASK(apiURL, parameters: nil, progress: nil, success: { task, response in
            if let dataResponse = response as? Data {
                if dataResponse.count == 0 {
                    failure?(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "Empty API response received from server."]))
                    return
                }
                
                // try to turn it into a string in case it was HTML
                if let responseString = String(data: dataResponse, encoding: .utf8) {
                    failure?(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "Invalid API response received from server. \(responseString)"]))
                    return
                }
            }
            
            guard let apiResponse = response as? [AnyHashable : Any] else {
                failure?(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "Unknown API response received from server. \(task.response?.mimeType ?? "unkonwn mime type")"]))
                return
            }
            
            if MageServer.checkServerCompatibility(api: apiResponse) {
                UserDefaults.standard.baseServerUrl = url.absoluteString
            } else {
                failure?(MageServer.generateServerCompatibilityError(api: apiResponse))
                return
            }
            
            UserDefaults.standard.locationServiceDisabled = apiResponse[ApiKey.locationServiceDisabled.key] as? Bool ?? false
            
            if let disclaimer = apiResponse[ApiKey.disclaimer.key] as? [String: Any] {
                UserDefaults.standard.showDisclaimer = disclaimer[DisclaimerKey.show.key] as? Bool ?? false
                UserDefaults.standard.disclaimerText = disclaimer[DisclaimerKey.text.key] as? String
                UserDefaults.standard.disclaimerTitle = disclaimer[DisclaimerKey.title.key] as? String
            }
            
            if let contactInfo = apiResponse[ApiKey.contactinfo.key] as? [String: Any] {
                UserDefaults.standard.contactInfoEmail = contactInfo[ContactInfoKey.email.key] as? String
                UserDefaults.standard.contactInfoPhone = contactInfo[ContactInfoKey.phone.key] as? String
            }
            // TODO: strategies value should be optional in case the server sends back something crazy
            if let authenticationStrategies = apiResponse[ApiKey.authenticationStrategies.key] as? [String: [AnyHashable: Any]] {
                UserDefaults.standard.authenticationStrategies = authenticationStrategies
                UserDefaults.standard.serverAuthenticationStrategies = authenticationStrategies
                var authenticationModules: [String: Any] = [:]
                for (authenticationStrategy, parameters) in authenticationStrategies {
                    if let authenticationModule = Authentication.authenticationModule(forStrategy: authenticationStrategy, parameters: parameters) {
                        authenticationModules[authenticationStrategy] = authenticationModule
                    }
                }
                if let oldLoginParameters = UserDefaults.standard.loginParameters, let oldUrl = oldLoginParameters[LoginParametersKey.serverUrl.key] as? String, oldUrl == url.absoluteString, StoredPassword.retrieveStoredPassword() != nil {
                    authenticationModules["offline"] = Authentication.authenticationModule(forStrategy:"offline", parameters:nil)
                }
                
                server.authenticationModules = authenticationModules
                
                success?(server)
                return
            } else {
                failure?(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "Invalid response from the MAGE server. \(apiResponse)"]))
                return
            }
        }, failure: { task, error in
            // check if the error indicates that the network is unavailable and return the offline authentication module
            let error = error as NSError
            if error.domain == NSURLErrorDomain
                && (error.code == NSURLErrorCannotConnectToHost
                    || error.code == NSURLErrorNetworkConnectionLost
                    || error.code == NSURLErrorNotConnectedToInternet
                    || error.code == NSURLErrorTimedOut
            ) {
                if let oldLoginParameters = UserDefaults.standard.loginParameters, let oldUrl = oldLoginParameters[LoginParametersKey.serverUrl.key] as? String, oldUrl == url.absoluteString, StoredPassword.retrieveStoredPassword() != nil {
                    if let authentication: AuthenticationProtocol = Authentication.authenticationModule(forStrategy: "offline", parameters: nil), authentication.canHandleLogin(toURL: url.absoluteString) {
                        server.authenticationModules = ["offline":authentication]
                    }
                    success?(server)
                } else {
                    // we can't log in offline because there are no offline credentials stored
                    failure?(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "Failed to connect to server.  Received error \(error.localizedDescription)"]))
                }
            } else {
                failure?(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "Failed to connect to server.  Received error \(error.localizedDescription)"]))
            }
        })
        
        if let task = task {
            manager?.addTask(task)
        }
    }
    
    public init(url: URL) {
        super.init()
        if url.absoluteString != UserDefaults.standard.baseServerUrl {
            return
        }
        
        // TODO: strategies value should be optional in case the server sends back something crazy
        if let authenticationStrategies = UserDefaults.standard.authenticationStrategies {
            UserDefaults.standard.serverAuthenticationStrategies = authenticationStrategies
            var authenticationModules: [String: Any] = [:]
            for (authenticationStrategy, parameters) in authenticationStrategies {
                if let authenticationModule = Authentication.authenticationModule(forStrategy: authenticationStrategy, parameters: parameters) {
                    authenticationModules[authenticationStrategy] = authenticationModule
                }
            }
            if let oldLoginParameters = UserDefaults.standard.loginParameters, let oldUrl = oldLoginParameters[LoginParametersKey.serverUrl.key] as? String, oldUrl == url.absoluteString, StoredPassword.retrieveStoredPassword() != nil {
                authenticationModules["offline"] = Authentication.authenticationModule(forStrategy:"offline", parameters:nil)
            }
            
            self.authenticationModules = authenticationModules
        }
    }

}

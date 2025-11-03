//
//  MageServer.swift
//  mage-ios-sdk
//
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import OSLog

@objc class MageServer: NSObject {
    
    // Single source of truth for "special" names the client treats specially.
    private enum StrategyKey {
        static let local   = "local"     // server-defined; we special-case ordering
        static let offline = "offline"   // client-only fallback
    }
    
    @objc public enum ServerConfigLoadPolicy: Int {
        /// Use cached server config if present; otherwise fetch from network.
        case useCachedIfAvailable
        /// Always fetch from network (re-read /api), ignoring cache.
        case forceRefresh
    }
    
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
    
    /// Strategies that the client treats as "IdP" (oauth2/oidc/saml/geoaxisconnect/idp).
    @objc public var oauthStrategies: [[String: Any]] {
        var result: [[String: Any]] = []
        if let strategies = UserDefaults.standard.serverAuthenticationStrategies {
            for (key, raw) in strategies {
                if Authentication.isIdpStrategy(key) {
                    let strategyDict = raw as? [String: Any] ?? [:]
                    result.append(["identifier": key, "strategy": strategyDict])
                }
            }
        }
        return result
    }
    
    /// All strategies from the server, ordered for UI.
    /// Non-local first (IdP and LDAP, etc.), then `local` last — preserving your current UX.
    /// Returns an empty array (not nil) for simpler callers.
    @objc public var strategies: [[String: Any]] {
        guard let defaults = UserDefaults.standard.serverAuthenticationStrategies else { return [] }

        var nonLocal: [[String: Any]] = []
        var local: [[String: Any]] = []

        for (key, raw) in defaults {
            let strategyDict = raw as? [String: Any] ?? [:]
            let item: [String: Any] = ["identifier": key, "strategy": strategyDict]
            if key == StrategyKey.local {
                local.append(item)
            } else {
                nonLocal.append(item)
            }
        }

        // Optional: stable order within each bucket
        nonLocal.sort { ($0["identifier"] as? String ?? "") < ($1["identifier"] as? String ?? "") }

        return nonLocal + local
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
    
    @objc public static func server(
        url: URL?,
        policy: ServerConfigLoadPolicy = .useCachedIfAvailable,
        success: ((MageServer) -> Void)?,
        failure: ((NSError) -> Void)?
    ) {
        guard let url = url, url.scheme != nil, url.host != nil else {
            failure?(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        let server = MageServer(url: url)
        
        // Only allow the early-return when policy == .useCachedIfAvailable
        let canServeFromCache = (policy == .useCachedIfAvailable)
        && (url.absoluteString == UserDefaults.standard.baseServerUrl)
        && (server.authenticationModules != nil)
        
        if canServeFromCache {
            success?(server)
            return
        }
        
        let manager = MageSessionManager.shared()
        let apiURL = "\(url.absoluteString)/api"
        let methodStart = Date()
        
        os_log("TIMING API @ %{public}@", "\(methodStart)")
        
        let task = manager?.get_TASK(apiURL, parameters: nil, progress: nil, success: { task, response in
            let elapsed = Date().timeIntervalSince(methodStart)
            os_log("TIMING Fetched API. Elapsed: %.3f seconds", elapsed)

            if let dataResponse = response as? Data {
                if dataResponse.count == 0 {
                    failure?(NSError(domain: NSURLErrorDomain,
                                     code: NSURLErrorBadURL,
                                     userInfo: [NSLocalizedDescriptionKey: "Empty API response received from server."]))
                    return
                }
                // Try to turn it into a string in case it was HTML/text
                if let responseString = String(data: dataResponse, encoding: .utf8) {
                    failure?(NSError(domain: NSURLErrorDomain,
                                     code: NSURLErrorBadURL,
                                     userInfo: [NSLocalizedDescriptionKey: "Invalid API response received from server. \(responseString)"]))
                    return
                }
            }
            
            guard let apiResponse = response as? [AnyHashable: Any] else {
                failure?(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "Unknown API response received from server. \(task.response?.mimeType ?? "unknown mime type")"]))
                return
            }
            
            if MageServer.checkServerCompatibility(api: apiResponse) {
                UserDefaults.standard.baseServerUrl = url.absoluteString
            } else {
                failure?(MageServer.generateServerCompatibilityError(api: apiResponse))
                return
            }
            
            // Single location that applies all API-derived settings & modules.
            do {
                try Self.applyApiResponse(apiResponse, to: server)
            } catch let error as NSError {
                failure?(error)
                return
            }
            
            success?(server)
        }, failure: { task, error in
            // check if the error indicates that the network is unavailable and return the offline authentication module
            let error = error as NSError
            
            if error.domain == NSURLErrorDomain && (
                error.code == NSURLErrorCannotConnectToHost ||
                error.code == NSURLErrorNetworkConnectionLost ||
                error.code == NSURLErrorNotConnectedToInternet ||
                error.code == NSURLErrorTimedOut
            ) {
                if let oldLoginParameters = UserDefaults.standard.loginParameters,
                   let oldUrl = oldLoginParameters[LoginParametersKey.serverUrl.key] as? String,
                   oldUrl == url.absoluteString,
                   StoredPassword.retrieveStoredPassword() != nil,
                   let authentication: AuthenticationProtocol = Authentication.authenticationModule(forStrategy: StrategyKey.offline, parameters: nil),
                   authentication.canHandleLogin(toURL: url.absoluteString) {
                    server.authenticationModules = [StrategyKey.offline: authentication]
                    success?(server)
                } else {
                    failure?(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL,
                                     userInfo: [NSLocalizedDescriptionKey: "\(error.localizedDescription)"]))
                }
            } else {
                let statusCode = (task?.response as? HTTPURLResponse)?.statusCode ?? nil
                failure?(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL,
                                 userInfo: [NSLocalizedDescriptionKey: "\(error.localizedDescription)",
                                            "statusCode": statusCode as Any,
                                            "originalError": error]))
            }
        })
        
        if let task = task {
            manager?.addTask(task)
        }
    }
    
    // One place to apply API -> defaults/modules (also handles contactInfo change detection).
    private static func applyApiResponse(_ api: [AnyHashable: Any], to server: MageServer) throws {
        UserDefaults.standard.locationServiceDisabled = api[ApiKey.locationServiceDisabled.key] as? Bool ?? false
        
        if let disclaimer = api[ApiKey.disclaimer.key] as? [String: Any] {
            UserDefaults.standard.showDisclaimer = disclaimer[DisclaimerKey.show.key] as? Bool ?? false
            UserDefaults.standard.disclaimerText = disclaimer[DisclaimerKey.text.key] as? String
            UserDefaults.standard.disclaimerTitle = disclaimer[DisclaimerKey.title.key] as? String
        }
        
        if let contactInfo = api[ApiKey.contactInfo.key] as? [String: Any] {
            let newEmail = contactInfo[ContactInfoKey.email.key] as? String
            let newPhone = contactInfo[ContactInfoKey.phone.key] as? String
            let oldEmail = UserDefaults.standard.contactInfoEmail
            let oldPhone = UserDefaults.standard.contactInfoPhone
            
            if oldEmail != newEmail || oldPhone != newPhone {
                UserDefaults.standard.contactInfoEmail = newEmail
                UserDefaults.standard.contactInfoPhone = newPhone
            }
        }
        
        guard let strategies = api[ApiKey.authenticationStrategies.key] as? [String: [AnyHashable: Any]] else {
            throw NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL,
                          userInfo: [NSLocalizedDescriptionKey: "Invalid response from the MAGE server. \(api)"])
        }
        
        UserDefaults.standard.authenticationStrategies = strategies
        UserDefaults.standard.serverAuthenticationStrategies = strategies
        
        if let keys = UserDefaults.standard.serverAuthenticationStrategies?.keys.sorted() {
            os_log("Auth strategies from server: %{public}@", keys.joined(separator: ", "))
        }

        var modules: [String: Any] = [:]
        
        for (strategy, parameters) in strategies {
            if let module = Authentication.authenticationModule(forStrategy: strategy, parameters: parameters) {
                modules[strategy] = module
            }
        }
        
        // Offline authentication when appropriate
        if let oldLoginParameters = UserDefaults.standard.loginParameters,
           let oldUrl = oldLoginParameters[LoginParametersKey.serverUrl.key] as? String,
           oldUrl == UserDefaults.standard.baseServerUrl,
           StoredPassword.retrieveStoredPassword() != nil,
           let offline = Authentication.authenticationModule(forStrategy: StrategyKey.offline, parameters: nil) {
            modules[StrategyKey.offline] = offline
        } else if StoredPassword.retrieveStoredPassword() == nil {
            os_log("No stored password; offline module not attached.")
        }
        
        server.authenticationModules = modules
    }
    
    @objc(serverWithUrl:success:failure:)
    public static func serverObjC(
      url: URL?,
      success: ((MageServer) -> Void)?,
      failure: ((NSError) -> Void)?
    ) {
        // Force Refresh of login strategies so that changes in Admin server propogate to client
        // Otherwise the app needs to be deleted and reinstalled to re-fetch new authentication methods.
        server(url: url, policy: .forceRefresh, success: success, failure: failure)
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

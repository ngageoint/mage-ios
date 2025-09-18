//
//  MageServer.swift
//  mage-ios-sdk
//
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Authentication
import OSLog

@objc public final class MageServer: NSObject {
    static let kServerCompatibilitiesKey          = "serverCompatibilities"
    static let kServerMajorVersionKey             = "serverMajorVersion"
    static let kServerMinorVersionKey             = "serverMinorVersion"
    static let kServerAuthenticationStrategiesKey = "serverAuthenticationStrategies"
    
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
    
    public private(set) var authenticationModules: [String: AuthenticationModule] = [:]
    
    // MARK: - Server meta
    
    @objc public static func baseURL() -> URL? {
        if let s = UserDefaults.standard.baseServerUrl { return URL(string: s) }
        return nil
    }
    
    @objc public var serverHasLocalAuthenticationStrategy: Bool {
        (UserDefaults.standard.serverAuthenticationStrategies?["local"] != nil)
    }
    
    public static var isServerVersion5: Bool {
        UserDefaults.standard.serverMajorVersion == 5
    }
    
    @objc public static var isServerVersion6_0: Bool {
        UserDefaults.standard.serverMajorVersion == 6 && UserDefaults.standard.serverMinorVersion == 0
    }
    
    private func isIdpStrategy(_ key: String) -> Bool {
        switch key.lowercased() {
        case "oauth", "oauth2", "oidc", "saml", "geoaxisconnect", "idp": return true
        default: return false
        }
    }
    
    /// Strategies that the client treats as "IdP" (oauth2/oidc/saml/geoaxisconnect/idp).
    @objc public var oauthStrategies: [[String: Any]] {
        var result: [[String: Any]] = []
        if let strategies = UserDefaults.standard.serverAuthenticationStrategies {
            for (key, raw) in strategies where isIdpStrategy(key) {
                let strategyDict = raw as? [String: Any] ?? [:]
                result.append(["identifier": key, "strategy": strategyDict])
            }
        }
        return result
    }
    
    /// All strategies from the server ordered for UI (non-local first, then local).
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
    
    // MARK: - Compatibility
    
    @objc public static func checkServerCompatibility(api: [AnyHashable: Any]?) -> Bool {
        guard
            let ranges = UserDefaults.standard.serverCompatibilities,
            let api    = api,
            let ver    = api["version"] as? [AnyHashable: Any],
            let major  = ver["major"] as? Int,
            let minor  = ver["minor"] as? Int
        else { return false }
        
        for c in ranges {
            if let cMajor = c[kServerMajorVersionKey],
               let cMinor = c[kServerMinorVersionKey],
               cMajor == major,
               cMinor <= minor {
                UserDefaults.standard.serverMajorVersion = major
                UserDefaults.standard.serverMinorVersion = minor
                return true
            }
        }
        return false
    }
    
    @objc public static func generateServerCompatibilityError(api: [AnyHashable: Any]?) -> NSError {
        if let api = api,
           let ver = api["version"] as? [AnyHashable: Any],
           let major = ver["major"] as? Int,
           let minor = ver["minor"] as? Int,
           let micro = ver["micro"] as? Int
        {
            return NSError(domain: "MAGE", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "This version of the app is not compatible with version \(major).\(minor).\(micro) of the server.  Please contact your MAGE administrator for more information."
            ])
        }
        
        if let api,
           let pretty = String(data: try! JSONSerialization.data(withJSONObject: api, options: .prettyPrinted), encoding: .utf8 ) {
            return NSError(domain: "MAGE", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid server response \(pretty)"])
        }
        
        return NSError(domain: "MAGE", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid server response"])
    }
    
    // MARK: - Swift convenience that mirrors Obj-C selector `serverWithUrl:success:failure:`
    // TODO: - Needed? (BRENT)
    public class func server(
        withUrl url: URL,
        success: ((MageServer) -> Void)?,
        failure: ((NSError) -> Void)?
    ) {
        server(url: url, policy: .useCachedIfAvailable, success: success, failure: failure)
    }
    
    @objc public static func server(
        url: URL?,
        policy: ServerConfigLoadPolicy = .useCachedIfAvailable,
        success: ((MageServer) -> Void)?,
        failure: ((NSError) -> Void)?
    ) {
        guard let url, url.scheme != nil, url.host != nil else {
            failure?(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"]))
            return
        }
        
        let server = MageServer(url: url)
        
        // Only allow the early-return when policy == .useCachedIfAvailable
        let canServeFromCache = (policy == .useCachedIfAvailable)
            && (url.absoluteString == UserDefaults.standard.baseServerUrl)
            && !server.authenticationModules.isEmpty
        
        if canServeFromCache {
            success?(server)
            return
        }
        
        let manager = MageSessionManager.shared()
        let apiURL = "\(url.absoluteString)/api"
        let methodStart = Date()
        os_log("TIMING API @ %{public}@", "\(methodStart)")
        
        // SUCCESS
        let successBlock: (URLSessionDataTask?, Any?) -> Void = { task, response in
            let elapsed = Date().timeIntervalSince(methodStart)
            os_log("TIMING Fetched API. Elapsed: %.3f seconds", elapsed)
            
            if let data = response as? Data, data.count == 0 {
                failure?(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "Empty API response received from server."]))
                return
            }
            
            guard let api = response as? [AnyHashable: Any] else {
                let mime = (task?.response as? HTTPURLResponse)?.mimeType ?? "unknown mime type"
                failure?(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "Unknown API response received from server. \(mime)"]))
                return
            }
            
            if Self.checkServerCompatibility(api: api) {
                UserDefaults.standard.baseServerUrl = url.absoluteString
            } else {
                failure?(Self.generateServerCompatibilityError(api: api))
                return
            }
            
            do {
                try Self.applyApiResponse(api, to: server)
            } catch let err as NSError {
                failure?(err)
                return
            }
            
            success?(server)
        }
        
        // FAILURE
        let failureBlock: (URLSessionDataTask?, Error) -> Void = { task, err in
            let ns = err as NSError
            
            if ns.domain == NSURLErrorDomain &&
                [NSURLErrorCannotConnectToHost,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorNotConnectedToInternet,
                 NSURLErrorTimedOut].contains(ns.code) {
                
                if let oldLogin = UserDefaults.standard.loginParameters,
                   let oldUrl = oldLogin[LoginParametersKey.serverUrl.key] as? String,
                   oldUrl == url.absoluteString {
                    
                    if let offline = AuthFactory.make(strategy: StrategyKey.offline, parameters: nil),
                       offline.canHandleLogin(toURL: url.absoluteString) {
                        
                        server.authenticationModules = [StrategyKey.offline: offline]
                        success?(server)
                        return
                    }
                }
                
                failure?(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: ns.localizedDescription]))
            } else {
                let status = (task?.response as? HTTPURLResponse)?.statusCode
                failure?(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL,
                                 userInfo: [NSLocalizedDescriptionKey: ns.localizedDescription,
                                            "statusCode": status as Any,
                                            "originalError": ns]))
            }
        }
        
        let task = manager?.get_TASK(
            apiURL,
            parameters: nil,
            progress: nil,
            success: successBlock,
            failure: failureBlock
        )
        
        if let task { manager?.addTask(task) }
    }
    
    // One place to apply API -> defaults/modules (also handles contactInfo change detection).
    private static func applyApiResponse(_ api: [AnyHashable: Any], to server: MageServer) throws {
        UserDefaults.standard.locationServiceDisabled = api[ApiKey.locationServiceDisabled.key] as? Bool ?? false
        
        if let disclaimer = api[ApiKey.disclaimer.key] as? [String: Any] {
            UserDefaults.standard.showDisclaimer  = disclaimer[DisclaimerKey.show.key] as? Bool ?? false
            UserDefaults.standard.disclaimerText  = disclaimer[DisclaimerKey.text.key] as? String
            UserDefaults.standard.disclaimerTitle = disclaimer[DisclaimerKey.title.key] as? String
        }
        
        if let contact = api[ApiKey.contactinfo.key] as? [String: Any] {
            let newEmail = contact[ContactInfoKey.email.key] as? String
            let newPhone = contact[ContactInfoKey.phone.key] as? String

            if UserDefaults.standard.contactInfoEmail != newEmail || UserDefaults.standard.contactInfoPhone != newPhone {
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
        
        var built: [String: AuthenticationModule] = [:]
        
        
        for (strategy, params) in strategies {
            if let module = AuthFactory.make(strategy: strategy, parameters: params) {
                built[strategy] = module
            }
        }
        
        // Offline authentication when appropriate
        if let oldLogin = UserDefaults.standard.loginParameters,
           let oldUrl = oldLogin[LoginParametersKey.serverUrl.key] as? String,
           oldUrl == UserDefaults.standard.baseServerUrl,
           StoredPassword.retrieveStoredPassword() != nil,
           let offline = AuthFactory.make(strategy: StrategyKey.offline, parameters: nil) {
            built[StrategyKey.offline] = offline
        }
        
        server.authenticationModules = built
    }
    
    @objc(serverWithUrl:success:failure:)
    public static func serverObjC(
        url: URL?,
        success: ((MageServer) -> Void)?,
        failure: ((NSError) -> Void)?
    ) {
        server(url: url, policy: .useCachedIfAvailable, success: success, failure: failure)
    }
    
    public init(url: URL) {
        super.init()
        if url.absoluteString != UserDefaults.standard.baseServerUrl { return }
        
        if let strategies = UserDefaults.standard.authenticationStrategies {
            var modules: [String: AuthenticationModule] = [:]
            
            for (strategy, params) in strategies {
                if let module = AuthFactory.make(strategy: strategy, parameters: params) {
                    modules[strategy] = module
                }
            }
            
            if let oldLogin = UserDefaults.standard.loginParameters,
                let oldUrl = oldLogin[LoginParametersKey.serverUrl.key] as? String,
                oldUrl == url.absoluteString,
                StoredPassword.retrieveStoredPassword() != nil,
               let offline = AuthFactory.make(strategy: StrategyKey.offline, parameters: nil) {
                modules[StrategyKey.offline] = offline
            }
            
            self.authenticationModules = modules
        }
    }
}

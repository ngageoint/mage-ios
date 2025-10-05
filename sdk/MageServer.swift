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
    static let kServerMicroVersionKey             = "serverMicroVersion"
    static let kServerAuthenticationStrategiesKey = "serverAuthenticationStrategies"
    
    @objc public enum ServerConfigLoadPolicy: Int {
        /// Use cached server config if present; otherwise fetch from network.
        case useCachedIfAvailable
        /// Always fetch from network (re-read /api), ignoring cache.
        case forceRefresh
    }
    
    public var authenticationModules: [String: AuthenticationModule] = [:]
    
    private typealias StrategyParams = [AnyHashable: Any]
    private typealias Strategies     = [String: StrategyParams]
    
    // MARK: - Server meta
    
    @objc public static func baseURL() -> URL? {
        if let s = UserDefaults.standard.baseServerUrl { return URL(string: s) }
        return nil
    }
    
    @objc public var serverHasLocalAuthenticationStrategy: Bool {
        (UserDefaults.standard.serverAuthenticationStrategies?[StrategyKind.local.rawValue] != nil)
    }
    
    public static func isServer(major: Int, minor: Int? = nil) -> Bool {
        let mj = UserDefaults.standard.serverMajorVersion
        let mn = UserDefaults.standard.serverMinorVersion
        if let minor { return mj == major && mn == minor }
        return mj == major
    }
    
    public static func isServerAtLeast(major: Int, minor: Int = 0) -> Bool {
        let mj = UserDefaults.standard.serverMajorVersion
        let mn = UserDefaults.standard.serverMinorVersion
        if mj != major { return mj > major }
        return mn >= minor
    }
    
    /// Strategies that the client treats as "IdP" (oauth/oidc/saml/geoaxisconnect).
    @objc public var oauthStrategies: [[String: Any]] {
        guard let strategies = UserDefaults.standard.serverAuthenticationStrategies else { return [] }
        
        return strategies.compactMap { key, raw in
            guard StrategyKind(string: key) == .idp else { return nil }
            let dict = raw as? [String: Any] ?? [:]
            return["identifier": key, "strategy": dict]
        }
    }
    
    /// All strategies from the server ordered for UI (non-local first, then local).
    @objc public var strategies: [[String: Any]] {
        guard let defaults = UserDefaults.standard.serverAuthenticationStrategies else { return [] }
        
        var nonLocal: [[String: Any]] = []
        var local:    [[String: Any]] = []
        
        for (key, raw) in defaults {
            let dict: [String: Any] = ["identifier": key, "strategy": (raw as? [String: Any] ?? [:])]
            
            if key == StrategyKind.local.rawValue {
                local.append(dict)
            } else {
                nonLocal.append(dict)
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
        
        let micro = ver["micro"] as? Int ?? 0
        
        for c in ranges {
            if let cMajor = c[kServerMajorVersionKey],
               let cMinor = c[kServerMinorVersionKey],
               cMajor == major,
               cMinor <= minor {
                UserDefaults.standard.serverMajorVersion = major
                UserDefaults.standard.serverMinorVersion = minor
                UserDefaults.standard.serverMicroVersion = micro
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
    
    @objc public static func server(
        url: URL?,
        policy: ServerConfigLoadPolicy = .useCachedIfAvailable,
        success: ((MageServer) -> Void)?,
        failure: ((NSError) -> Void)?
    ) {
        // Always deliver results on the main thread for UI safety.
        @inline(__always)
        func finishSuccess(_ s: MageServer) {
            DispatchQueue.main.async { success?(s) }
        }
        
        @inline(__always)
        func finishFailure(_ e: NSError) {
            DispatchQueue.main.async { failure?(e) }
        }
        
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
            finishSuccess(server)
            return
        }
        
        let manager     = MageSessionManager.shared()
        let apiURL      = "\(url.absoluteString)/api"
        let methodStart = Date()
        os_log("TIMING API @ %{public}@", "\(methodStart)")
        
        // SUCCESS
        let successBlock: (URLSessionDataTask?, Any?) -> Void = { task, response in
            let elapsed = Date().timeIntervalSince(methodStart)
            os_log("TIMING Fetched API. Elapsed: %.3f seconds", elapsed)
            
            if let data = response as? Data, data.count == 0 {
                finishFailure(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "Empty API response received from server."]))
                return
            }
            
            guard let api = response as? [AnyHashable: Any] else {
                let mime = (task?.response as? HTTPURLResponse)?.mimeType ?? "unknown mime type"
                finishFailure(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "Unknown API response received from server. \(mime)"]))
                return
            }
            
            if Self.checkServerCompatibility(api: api) {
                UserDefaults.standard.baseServerUrl = url.absoluteString
            } else {
                finishFailure(Self.generateServerCompatibilityError(api: api))
                return
            }
            
            do {
                try Self.applyApiResponse(api, to: server)
            } catch let err as NSError {
                finishFailure(err)
                return
            }
            
            finishSuccess(server)
        }
        
        // FAILURE
        let failureBlock: (URLSessionDataTask?, Error) -> Void = { task, err in
            let ns = err as NSError
            
            if ns.domain == NSURLErrorDomain &&
                [NSURLErrorCannotConnectToHost,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorNotConnectedToInternet,
                 NSURLErrorTimedOut].contains(ns.code) {
                
                if let offline = Self.offlineModuleIfEligible(for: url.absoluteString) {
                    server.authenticationModules = [StrategyKind.offline.rawValue: offline]
                    finishSuccess(server)
                    return
                }
                
                finishFailure(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: ns.localizedDescription]))
            } else {
                let status = (task?.response as? HTTPURLResponse)?.statusCode
                finishFailure(NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL,
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
    
    // MARK: - Async API
    
    /// Loads/refreshes the server config and returns a `MageServer`.
    /// Main-thread guaranteed (safe to touch UI after).
    @MainActor
    public static func server(
        url: URL?,
        policy: ServerConfigLoadPolicy = .useCachedIfAvailable
    ) async throws -> MageServer {
        try await withCheckedThrowingContinuation { cont in
            server(url: url, policy: policy, success: { srv in
                cont.resume(returning: srv)
            }, failure: { err in
                cont.resume(throwing: err)
            })
        }
    }

    /// Convenience overload that defaults to `.useCachedIfAvailable`.
    @MainActor
    public static func server(url: URL?) async throws -> MageServer {
        try await server(url: url, policy: .useCachedIfAvailable)
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
        
        let base = UserDefaults.standard.baseServerUrl ?? ""
        server.authenticationModules = Self.buildModules(from: strategies, baseURLString: base)
    }
    
    private static func buildModules(from strategies: Strategies, baseURLString: String) -> [String: AuthenticationModule] {
        var built: [String: AuthenticationModule] = [:]
        
        for (strategy, params) in strategies {
            if let module = AuthFactory.make(strategy: strategy, parameters: params) {
                built[strategy] = module
            }
        }
        
        if let offline = offlineModuleIfEligible(for: baseURLString) {
            built[StrategyKind.offline.rawValue] = offline
        }
        
        return built
    }
    
    /// Centralized policy for enabling Offline
    private static func offlineModuleIfEligible(for baseURLString: String) -> AuthenticationModule? {
        guard
            let oldLogin = UserDefaults.standard.loginParameters,
            let oldUrl   = oldLogin[LoginParametersKey.serverUrl.key] as? String,
            oldUrl == baseURLString,
            AuthDependencies.shared.requireAuthStore.hasStoredPassword(),
            let offline = AuthFactory.make(kind: .offline, parameters: nil),
            offline.canHandleLogin(toURL: baseURLString)
        else {
            return nil
        }
        return offline
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
        
        // Only populate from cache if URL matches stored base URL.
        guard url.absoluteString == UserDefaults.standard.baseServerUrl else { return }
        
        if let strategies = UserDefaults.standard.authenticationStrategies {
            self.authenticationModules = Self.buildModules(from: strategies, baseURLString: url.absoluteString)
        }
    }
    
    // MARK - Typed accessors for modules
    
    public func module(for kind: StrategyKind) -> AuthenticationModule? {
        authenticationModules[kind.rawValue]
    }
    
    public func setModule(_ module: AuthenticationModule, for kind: StrategyKind) {
        authenticationModules[kind.rawValue] = module
    }
}



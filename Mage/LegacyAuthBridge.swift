//
//  LegacyAuthBridge.swift
//  MAGE
//
//  Created by Brent Michalski on 9/8/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc public protocol _ObjCAuthenticationProtocol {
    init(paremeters: [AnyHashable: Any])
    func parameters() -> [AnyHashable: Any]
    func canHandleLogin(toURL url: String) -> Bool
    func login(withParameters params: [AnyHashable: Any],
               complete: @escaping (AuthenticationStatus, String?) -> Void)
    func finishLogin(_ complete: @escaping (AuthenticationStatus, String?, String?) -> Void)
}

public struct LegacyAuthBridge {
    public let modules: [String: _ObjCAuthenticationProtocol]  // strategy -> module
    
    public init(server: MageServer) {
        var m: [String: _ObjCAuthenticationProtocol] = [:]
        (server.authenticationModules ?? [:]).forEach { key, value in
            if let mod = value as? _ObjCAuthenticationProtocol {
                m[key as? String ?? ""] = mod
            }
        }
        self.modules = m
    }
    
    public func login(strategy: String,
                      params: [AnyHashable: Any],
                      complete: @escaping (AuthenticationStatus, String?) -> Void) {
        guard let mod = modules[strategy] ?? modules["offline"] else {
            complete(.UNABLE_TO_AUTHENTICATE, "No module"); return
        }
        
        mod.login(withParameters: params, complete: complete)
    }
    
    public func finishLogin(strategy: String,
                            complete: @escaping (AuthenticationStatus, String?, String?) -> Void) {
        guard let mod = modules[strategy] ?? modules["offline"] else {
            complete(.UNABLE_TO_AUTHENTICATE, "No module", nil); return
        }
        
        mod.finishLogin(complete)
    }
    
    
}

//
//  LocalAuth.swift
//  Authentication
//
//  Created by Brent Michalski on 9/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

// MARK: - Local (username/password)
public final class LocalAuth: AuthenticationModule {
    private let params: [AnyHashable: Any]?
    public required init(parameters: [AnyHashable: Any]?) { self.params = parameters }
    
    public func canHandleLogin(toURL url: String) -> Bool { true }
    
    public func login(withParameters params: [AnyHashable : Any],
                      complete: @escaping (AuthenticationStatus, String?) -> Void) {
        guard
            let base = (params["serverUrl"] as? String) ?? AuthDefaults.baseServerUrl,
            let url = URL(string: "\(base)/auth/local/signin"),
            let username = params.string("username") ?? params.string("email"),
            let password = params.string("password")
        else {
            complete(.unableToAuthenticate, "Missing credentials or server URL")
            return
        }
        
        Task {
            do {
                let (status, data) = try await AuthDependencies.shared.http.postJSON(
                    url: url,
                    headers: [:],
                    body: ["username": username, "password": password],
                    timeout: 30
                )
                
                switch status {
                case 200:
                    complete(.success, nil)
                case 401:
                    complete(.unableToAuthenticate, "Invalid username or password.")
                default:
                    let msg = String(data: data, encoding: .utf8)?
                        .trimmingCharacters(in: .whitespacesAndNewlines) ?? "Login failed (\(status))"
                    complete(.error, msg)
                }
            } catch {
                // Transport or serialization error
                complete(.error, error.localizedDescription)
            }
        }
//        
//        
//        HTTP.postJSON(url, body: ["username": username, "password": password]) { code, data, err in
//            if let err { return complete(.error, err.localizedDescription) }
//            
//            switch code {
//            case 200: complete(.success, nil)
//            case 401: complete(.unableToAuthenticate, "Invalid username or password.")
//            default:
//                let msg = data.flatMap { String(data: $0, encoding: .utf8) } ?? "Login failed (\(code))"
//                complete(.error, msg)
//            }
//        }
        
        
        
    }
    
    public func finishLogin(complete: @escaping (AuthenticationStatus, String?, String?) -> Void) {
        complete(.success, nil, nil)
    }
    
}

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
                let (status, data, headers) = try await AuthDependencies.shared.http.postJSONWithHeaders(
                    url: url,
                    headers: [:],
                    body: ["username": username, "password": password],
                    timeout: 30
                )
                
                if let authErr = HTTPErrorMapper.map(
                    status: status,
                    headers: headers,
                    bodyData: data
                ) {
                    let (mappedStatus, message) = authErr.toAuthStatusAndMessage(fallbackInvalidCredsMessage: "Invalid username or password.")
                    complete(mappedStatus, message)
                } else {
                    // Transport / no HTTP response
                    complete(.success, nil)
                }
            } catch {
                // Transport or serialization error
                complete(.error, error.localizedDescription)
            }
        }
    }
    
    public func finishLogin(complete: @escaping (AuthenticationStatus, String?, String?) -> Void) {
        complete(.success, nil, nil)
    }
    
}

//
//  LDAPAuth.swift
//  Authentication
//
//  Created by Brent Michalski on 9/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

public final class LDAPAuth: AuthenticationModule {
    private let params: [AnyHashable: Any]?
    public required init(parameters: [AnyHashable: Any]?) { self.params = parameters }
    
    public func canHandleLogin(toURL url: String) -> Bool { true }
    
    public func login(withParameters params: [AnyHashable : Any], complete: @escaping (AuthenticationStatus, String?) -> Void) {
        guard
            let base = (params["serverUrl"] as? String) ?? AuthDefaults.baseServerUrl,
            let url = URL(string: "\(base)/auth/ldap/signin"),
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
                
                if let authErr = HTTPErrorMapper.map(status: status,
                                                     headers: [:],
                                                     bodyData: data) {
                    
                    let (mappedStatus, message) = Self.mapAuthError(authErr,
                                                                    fallbackInvalidCredsMessage: "Invalid LDAP credentials.")
                    complete(mappedStatus, message)
                } else {
                    // 2xx
                    complete(.success, nil)
                }
            } catch {
                // Transport error (no HTTP response)
                complete(.error, error.localizedDescription)
            }
        }
    }
    
    public func finishLogin(complete: @escaping (AuthenticationStatus, String?, String?) -> Void) {
        complete(.success, nil, nil)
    }
}


private extension LDAPAuth {
    static func mapAuthError(
        _ err: AuthError,
        fallbackInvalidCredsMessage: String
    ) -> (AuthenticationStatus, String?) {
        
        switch err {
        case .unauthorized:
            return (.unableToAuthenticate, fallbackInvalidCredsMessage)
            
        case .invalidCredentials:
            return (.unableToAuthenticate, fallbackInvalidCredsMessage)
            
        case .accountDisabled:
            return (.unableToAuthenticate, "Account disabled.")
            
        case .rateLimited(let retryAfterSeconds):
            let msg: String
            if let s = retryAfterSeconds, s > 0 {
                msg = "Too many attempts. Try again in \(s)s."
            } else {
                msg = "Too many attempts. Try again later."
            }
            return(.error, msg)
            
        case .invalidInput(let message):
            return (.error, message ?? "Invalid input.")
            
        case .server(let status, let message):
            return (.error, message ?? "Server error: \(status)).")
            
        case .network(underlying: let underlying):
            let message: String
            
            if let urlErr = underlying as? URLError {
                switch urlErr.code {
                case .notConnectedToInternet:
                    message = "No internet connection."
                case .timedOut:
                    message = "The request timed out."
                case .cannotFindHost:
                    message = "Can't connect to the server."
                case .networkConnectionLost:
                    message = "Network connection was lost."
                case .secureConnectionFailed, .serverCertificateUntrusted,
                        .serverCertificateHasBadDate, .serverCertificateHasUnknownRoot,
                        .serverCertificateNotYetValid, .clientCertificateRejected,
                        .clientCertificateRequired:
                    message = "Secure connection failed."
                default:
                    message = urlErr.localizedDescription
                }
            } else {
                message = underlying.localizedDescription
            }
            return (.error, message)
            
        case .malformedResponse:
            return (.error, "Malformed server response")
            
        case .configuration:
            return (.error, "Authentication configuration error. Please contact support.")
            
        case .cancelled:
            return (.error, "Request was cancelled.")
            
        @unknown default:
            return (.error, String(describing: err))
            
        }
    }
}

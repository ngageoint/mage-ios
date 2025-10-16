//
//  AuthEndpoint.swift
//  MAGE
//
//  Created by Brent Michalski on 10/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

enum AuthEndpoint {
    case loginLocal(username: String, password: String)
    case signup(displayName: String, username: String, password: String, email: String?, captcha: String?)
    case captcha(username: String?)
    case changePassword(current: String, new: String, confirm: String)
    
    var request: HTTPRequest {
        switch self {
        case let .loginLocal(u, p):
            return HTTPRequest(method: "POST", path: "/api/login", body: json(["username": u, "password": p]))
        case let .signup(d,u,p,e,c):
            return HTTPRequest(method: "POST", path: "/api/users", body: json([
                "displayName": d, "username": u, "password": p, "email": e as Any, "captchaText": c as Any
            ]))
        case let .captcha(u):
            return HTTPRequest(method: "GET", path: "/api/captcha?u=\(u ?? "")", body: nil)
        case let .changePassword(cur, new, conf):
            return HTTPRequest(method: "PUT", path: "/api/users/myself/password", body: json([
                "password": cur, "newPassword": new, "newPasswordConfirm": conf
            ]))
        }
    }
}


private func json(_ dict: [String: Any]) -> Data? {
    try? JSONSerialization.data(withJSONObject: dict, options: [])
}

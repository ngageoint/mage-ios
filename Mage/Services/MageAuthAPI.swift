//
//  MageAuthAPI.swift
//  MAGE
//
//  Created by Brent Michalski on 9/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc public final class MageAuthAPI: NSObject {
    
    // GET /api/users/signups/verifications?username=&background=
    @objc public class func getSignupCaptcha(
        forUsername username: String,
        background: String,
        completion: @escaping (_ token: String?, _ captchaBase64: String?, _ error: NSError?) -> Void
    ) {
        guard let base = MageServer.baseURL()?.absoluteString else {
            completion(nil, nil, NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "Missing base URL"]))
            return
        }
        
        let allowed = CharacterSet.urlQueryAllowed
        let u = username.addingPercentEncoding(withAllowedCharacters: allowed) ?? username
        let b = background.addingPercentEncoding(withAllowedCharacters: allowed) ?? background
        let url = "\(base)/api/users/signups/verifications?username=\(u)&background=\(b)"
        
        let mgr = MageSessionManager.shared()
        let task = mgr?.get_TASK(url, parameters: nil, progress: nil, success: { task, response in
            // response may be JSON or Data; handle both
            if let dict = response as? [String: Any] {
                let token = (dict["tokan"] as? String) ?? (dict["id"] as? String)
                let captcha = (dict["captcha"] as? String) ?? (dict["imageBase64"] as? String)
                completion(token, captcha, nil)
            } else if let data = response as? Data,
                      let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                let token = (dict["token"] as? String) ?? (dict["id"] as? String)
                let captcha = (dict["captcha"] as? String) ?? (dict["imageBase64"] as? String)
                completion(token, captcha, nil)
            } else {
                completion(nil, nil, NSError(domain: NSURLErrorDomain, code: NSURLErrorBadServerResponse,
                                             userInfo: [NSLocalizedDescriptionKey: "Unexpected captcha response"]))
            }
        }, failure: { task, error in
            completion(nil, nil, error as NSError)
        })
        
        if let task { mgr?.addTask(task) }
    }
    
    // POST /api/users/signups/verifications (token sent along with body)
    @objc public class func completeSignup(
        withParameters params: [String: Any],
        token: String,
        completion: @escaping (_ http: HTTPURLResponse?, _ body: Data?, _ error: NSError?) -> Void
    ) {
        guard let base = MageServer.baseURL()?.absoluteString else {
            completion(nil, nil, NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL,
                                         userInfo: [NSLocalizedDescriptionKey: "Missing base URL"]))
            return
        }
        
        let url = "\(base)/api/users/signups/verifications"
        
        // If your server expects the token in headers, add it here. If it expects it in the body, you're already passing it.
        let mgr = MageSessionManager.shared()
        let task = mgr?.post_TASK(url, parameters: params, progress: nil, success: { task, response in
            completion(task.response as? HTTPURLResponse, response as? Data, nil)
        }, failure: { task, error in
            completion(task?.response as? HTTPURLResponse, nil, error as NSError)
        })
        if let task { mgr?.addTask(task) }
    }
    
    // PUT/POST change password (path can be adjusted to match server)
    @objc public class func changePassword(
        currentPassword: String,
        newPassword: String,
        confirmedPassword: String,
        completion: @escaping(_ http: HTTPURLResponse?, _ error: NSError?) -> Void
    ) {
        guard let base = MageServer.baseURL()?.absoluteString else {
            completion(nil, NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL, userInfo: [NSLocalizedDescriptionKey: "Missing base URL"]))
            return
        }
        
        let url = "\(base)/api/users/me/password"
        let body: [String: Any] = [
            "currentPassword": currentPassword,
            "password": newPassword,
            "passwordconfirm": confirmedPassword
        ]
        
        let mgr = MageSessionManager.shared()
        // If you don't have put_TASK, using post_TASK works too if server accepts POST.
        let task = mgr?.put_TASK(url, parameters: body, success: { task, _ in
            completion(task.response as? HTTPURLResponse, nil)
        }, failure: { task, error in
            completion(task?.response as? HTTPURLResponse, error as NSError)
        }) ?? mgr?.post_TASK(url, parameters: body, progress: nil, success: { task, _ in
            completion(task.response as? HTTPURLResponse, nil)
        }, failure: { task, error in
            completion(task?.response as? HTTPURLResponse, error as NSError)
        })
        
        if let task { mgr?.addTask(task) }
    }
}

//
//  MageAuthAPI.swift
//  MAGE
//
//  Created by Brent Michalski on 9/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@objc public final class MageAuthAPI: NSObject {
    
    // MARK: - CAPTCHA
    
    // GET /api/users/signups/verifications?username=&background=
    // Completion: (token, imageBase64, error)
    @objc public class func getSignupCaptcha(
        forUsername username: String,
        background: String,
        completion: @escaping (_ token: String?, _ base64: String?, _ error: NSError?) -> Void
    ) {
        
        let url = "/api/users/signups/verifications"
        let params: [String: Any] = [
            "username": username,
            "background": background
        ]
        
        let sessionManager = MageSessionManager.shared()

        let task = sessionManager?.get_TASK(
            url,
            parameters: params,
            progress: nil,
            success: { (task: URLSessionDataTask, response: Any?) in
                if let data = response as? Data {
                    if let json = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] {
                        let (tok, b64) = Self.parseCaptchaJSON(json)
                        completion(tok, b64, nil)
                    } else {
                        completion(nil, nil, Self.makeError(0, "Unexpected captcha response"))
                    }
                } else if let json = response as? [String: Any] {
                    let (tok, b64) = Self.parseCaptchaJSON(json)
                    completion(tok, b64, nil)
                } else {
                    completion(nil, nil, Self.makeError(0, "Unexpected captcha response"))
                }
            },
            failure: { (task: URLSessionDataTask?, error: Error) in
                completion(nil, nil, error as NSError)
            }
        )
        
        if let task { sessionManager?.addTask(task) }
    }
    
    private static func parseCaptchaJSON(_ json: [String: Any]) -> (String?, String?) {
        let token = (json["token"] as? String)
        ?? (json["verificationToken"] as? String)
        ?? (json["capthchaToken"] as? String)
        
        let base64 = (json["captcha"] as? String)
        ?? (json["image"] as? String)
        ?? (json["imageBase64"] as? String)
        
        return (token, base64)
    }
    
    
    // MARK: - SIGNUP
    
    /// POST /api/users/signups
    /// Expects the signup body + captcha token/text
    @objc public class func signup(
        withParameters parameters: [String: Any],
        captchaText: String,
        token: String,
        completion: @escaping (_ http: HTTPURLResponse?, _ error: NSError?) -> Void) {
            let url = "/api/users/signups"
            
            var body = parameters
            
            // Try multiple key names to match common backends (adjust to match yours exactly)
            body["captcha"] = captchaText
            body["captchaText"] = captchaText
            body["token"] = token
            body["verificationToken"] = token
            
            let sessionManager = MageSessionManager.shared()
            
            let task = sessionManager?.post_TASK(url, parameters: body, progress: nil, success: { task, _ in
                completion(task.response as? HTTPURLResponse, nil)
            }, failure: { task, error in
                completion(task?.response as? HTTPURLResponse, error as NSError)
            })
            
            if let task { sessionManager?.addTask(task) }
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
        
        let sessionManager = MageSessionManager.shared()
        // If you don't have put_TASK, using post_TASK works too if server accepts POST.
        let task = sessionManager?.put_TASK(url, parameters: body, success: { task, _ in
            completion(task.response as? HTTPURLResponse, nil)
        }, failure: { task, error in
            completion(task?.response as? HTTPURLResponse, error as NSError)
        }) ?? sessionManager?.post_TASK(url, parameters: body, progress: nil, success: { task, _ in
            completion(task.response as? HTTPURLResponse, nil)
        }, failure: { task, error in
            completion(task?.response as? HTTPURLResponse, error as NSError)
        })
        
        if let task { sessionManager?.addTask(task) }
    }

    
    // MARK: - Utils & Helpers
    private static func makeError(_ code: Int, _ message: String) -> NSError {
        NSError(domain: "MAGE.Auth", code: code, userInfo: [NSLocalizedDescriptionKey: message])
    }
}


/// OLD: - delete before release
//@objc public class func completeSignup(
//    withParameters params: [String: Any],
//    token: String,
//    completion: @escaping (_ http: HTTPURLResponse?, _ body: Data?, _ error: NSError?) -> Void
//) {
//    guard let base = MageServer.baseURL()?.absoluteString else {
//        completion(nil, nil, NSError(domain: NSURLErrorDomain, code: NSURLErrorBadURL,
//                                     userInfo: [NSLocalizedDescriptionKey: "Missing base URL"]))
//        return
//    }
//    
//    let url = "\(base)/api/users/signups/verifications"
//    
//    // If your server expects the token in headers, add it here. If it expects it in the body, you're already passing it.
//    let sessionManager = MageSessionManager.shared()
//    let task = sessionManager?.post_TASK(url, parameters: params, progress: nil, success: { task, response in
//        completion(task.response as? HTTPURLResponse, response as? Data, nil)
//    }, failure: { task, error in
//        completion(task?.response as? HTTPURLResponse, nil, error as NSError)
//    })
//    if let task { sessionManager?.addTask(task) }
//}

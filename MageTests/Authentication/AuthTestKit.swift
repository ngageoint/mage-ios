//
//  AuthTestKit.swift
//  MAGETests
//
//  Created by Brent Michalski on 8/28/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import XCTest
import OHHTTPStubs
@testable import MAGE

// MARK: - Constants

enum TestURLs {
    static let base = "https://magetest"
    static func absPath(_ path: String) -> String { "\(base)\(path)" }
    
    static let api           = absPath("/api")
    static let apiServer     = absPath("/api/server")
    
    static let signinLocal   = absPath("/auth/local/signin")
    static let token         = absPath("/auth/token")
    
    static let signups       = absPath("/api/users/signups")
    static let signupsVerify = absPath("/api/users/signups/verifications")
}

// MARK: - Stub helpers (thos ones you call from tests)

enum Stubs {
    // --- Common cleanup
    static func removeAll() {
        HTTPStubs.removeAllStubs()
    }
    
    // ---- Server "/api" + "/api/server"
    @discardableResult
    static func api(
        apiFixture: String = "apiSuccess6.json",
        serverFixture: String = "server_response.json",
        delegate: MockMageServerDelegate) -> MockMageServerDelegate {
            installJSONStub(urlString: TestURLs.api, file: apiFixture, delegate: delegate)
            installJSONStub(urlString: TestURLs.apiServer, file: serverFixture, delegate: delegate)
            return delegate
        }
    
    // ---- Local auth happy path (signin + token)
    @discardableResult
    static func authSuccess(
        signinFixture: String = "signinSuccess.json",
        tokenFixture: String = "tokenSuccess.json",
        delegate: MockMageServerDelegate) -> MockMageServerDelegate {
            installJSONStub(urlString: TestURLs.signinLocal, file: signinFixture, delegate: delegate)
            installJSONStub(urlString: TestURLs.token, file: tokenFixture, delegate: delegate)
            return delegate
        }
    
    /// silence /api/users/.../(avatar | icon) to avoid host-not-found spam during flows
    static func userAssetsNoop() {
        HTTPStubs.stubRequests(passingTest: { req in
            guard let url = req.url, url.host == "magetest" else { return false }
            let p = url.path
            return p.hasPrefix( "/api/users/" ) && ( p.hasSuffix( "/avatar" ) || p.hasSuffix( "/icon" ) )
        }) { _ in
            HTTPStubsResponse(data: Data(), statusCode: 200, headers: ["Content-Type": "image/png"]).responseTime(0.01)
        }
    }
    
    // ---- Local auth: only signin success (token omitted if you want to assert failure separately)
    @discardableResult
    static func authSigninSuccessOnly(
        signinFixture: String = "signinSuccess.json",
        delegate: MockMageServerDelegate) -> MockMageServerDelegate {
            installJSONStub(urlString: TestURLs.signinLocal, file: signinFixture, delegate: delegate)
            return delegate
        }
    
    // ---- Force a network error on /auth/local/signin
    @discardableResult
    static func signinError(_ error: NSError, delegate: MockMageServerDelegate) -> HTTPStubsDescriptor {
        let u = URL(string: TestURLs.signinLocal)!
        
        return HTTPStubs.stubRequests(passingTest: { req in
            guard let url = req.url else { return false }
            return url.host == u.host && _pathsMatch(url.path, u.path)
        }) { req in
            delegate.urlCalled(req.url, method: req.httpMethod)
            return HTTPStubsResponse(error: error)
        }
    }
    

    
    // ---- Force an HTTP failure on /auth/token
    @discardableResult
    static func tokenFailure(
        status: Int32 = 401,
        body: String = "Failed to get a token",
        headers: [String: String]? = nil,
        delegate: MockMageServerDelegate) -> HTTPStubsDescriptor {
            let u = URL(string: TestURLs.token)!
            
            return HTTPStubs.stubRequests(passingTest: { req in
                guard let url = req.url else { return false }
                return url.host == u.host && _pathsMatch(url.path, u.path)
            }) { req in
                delegate.urlCalled(req.url, method: req.httpMethod)
                return HTTPStubsResponse(
                    data: Data(body.utf8), statusCode: status, headers: headers)
            }
        }
    
    // ---- Captcha (signups) success
    @discardableResult
    static func signupCaptcha(
        fixture: String = "signups.json",
        delegate: MockMageServerDelegate) -> MockMageServerDelegate {
            MockMageServer.stubJSONSuccessRequest(url: TestURLs.signups, filePath: fixture, delegate: delegate)
            return delegate
        }
    
    // ---- Signup verification success (JSON body optional for matching)
    @discardableResult
    static func signupVerificationSuccess(
        fixture: String,
        jsonBody: [String: Any]? = nil,
        delegate: MockMageServerDelegate) -> MockMageServerDelegate {
            MockMageServer.stubJSONSuccessRequest(url: TestURLs.signupsVerify, filePath: fixture, delegate: delegate)
            return delegate
        }
    
    // ---- Signup verification failure (e.g., 503)
    @discardableResult
    static func signupVerificationFailure(
        status: Int32 = 503,
        body: String = "error message",
        delegate: MockMageServerDelegate) -> HTTPStubsDescriptor {
            let u = URL(string: TestURLs.signupsVerify)!
            
            return HTTPStubs.stubRequests(passingTest: { req in
                guard let url = req.url else { return false }
                return url.host == u.host && _pathsMatch(url.path, u.path)
            }) { req in
                delegate.urlCalled(req.url, method: req.httpMethod)
                return HTTPStubsResponse(data: Data(body.utf8), statusCode: status, headers: ["Content-Type": "text/plain"])
            }
        }
}


// MARK: - Defaults helpers

enum Given {
    @discardableResult
    static func baseURL(_ url: String = TestURLs.base) -> Given.Type {
        UserDefaults.standard.baseServerUrl = url
        return self
    }
    
    @discardableResult
    static func registeredDevice(_ isRegistered: Bool = true) -> Given.Type {
        UserDefaults.standard.deviceRegistered = isRegistered
        return self
    }

    @discardableResult
    static func currentUser(id: String?) -> Given.Type {
        UserDefaults.standard.currentUserId = id
        return self
    }

    @discardableResult
    static func showDisclaimer(_ show: Bool?) -> Given.Type {
        if let show { UserDefaults.standard.set(show, forKey: "showDisclaimer") }
        else { UserDefaults.standard.removeObject(forKey: "showDisclaimer") }
        return self
    }

    @discardableResult
    static func storedPassword(username: String, password: String) -> Given.Type {
        UserDefaults.standard.loginParameters = ["serverUrl": TestURLs.base, "username": username]
        StoredPassword.persistPassword(toKeyChain: password)
        return self
    }

    @discardableResult
    static func loginType(_ type: String?) -> Given.Type {
        UserDefaults.standard.loginType = type
        return self
    }
}

// MARK: - Stubbing helpers

@discardableResult
func stubAPI(success fixture: String = "apiSuccess6.json",
             serverFixture: String = "server_response.json",
             delegate: MockMageServerDelegate) -> MockMageServerDelegate {
    MockMageServer.stubJSONSuccessRequest(url: TestURLs.apiServer, filePath: serverFixture, delegate: delegate)
    MockMageServer.stubJSONSuccessRequest(url: TestURLs.api, filePath: fixture, delegate: delegate)
    return delegate
}

@discardableResult
func stubLocalAuth(signin fixtureSignIn: String? = nil,
                   token fixtureToken: String? = nil,
                   delegate: MockMageServerDelegate) -> MockMageServerDelegate {
    if let s = fixtureSignIn {
        MockMageServer.stubJSONSuccessRequest(url: TestURLs.signinLocal, filePath: s, delegate: delegate)
    }
    
    if let t = fixtureToken {
        MockMageServer.stubJSONSuccessRequest(url: TestURLs.token, filePath: t, delegate: delegate)
    }

    return delegate
}

func stubSigninError(_ error: NSError, delegate: MockMageServerDelegate) {
    let u = URL(string: TestURLs.signinLocal)!
    
    stub(condition: isHost(u.host!) && isPath(u.path)) { req in
        delegate.urlCalled(req.url, method: req.httpMethod)
        return HTTPStubsResponse(error: error)
    }
}

func stubToken(status: Int32, body: String, delegate: MockMageServerDelegate) {
//    OHHTTPStubs.stub
}

func stubUserAssets() {
    HTTPStubs.stubRequests(passingTest: { req in
        guard req.url?.host == "magetest" else { return false }
        let p = req.url?.path ?? ""
        return p.contains("/api/users") && (p.contains("/avatar") || p.contains("/icon"))
    }){ _ in
        HTTPStubsResponse(data: Data(), statusCode: 200, headers: ["Content-Type":"image/png"])
    }
    
}

final class _AuthTestKitBundleSentinel: NSObject { }

private extension Stubs {
    @discardableResult
    static func installJSONStub(urlString: String,
                                file: String,
                                contentType: String = "application/json",
                                delegate: MockMageServerDelegate) -> HTTPStubsDescriptor {
        
        let u = URL(string: urlString)!
        return HTTPStubs.stubRequests(passingTest: { req in
            guard let url = req.url else { return false }
            return url.host == u.host && _pathsMatch(url.path, u.path)
        }) { req in
            delegate.urlCalled(req.url, method: req.httpMethod)
            
            // Resolve the fixture inside the *test* bundle
            guard let path = Bundle(for: _AuthTestKitBundleSentinel.self)
                .path(forResource: file, ofType: nil) else {
                assertionFailure("Fixture '\(file)' not found in test bundle")
                return HTTPStubsResponse(data: Data(), statusCode: 500, headers: nil)
            }
            
            // tiny delay avoids 0-latency races
            return HTTPStubsResponse(fileAtPath: path, statusCode: 200, headers: ["Content-Type": contentType])
                .responseTime(0.01)
        }
    }
}

@inline(__always)
func _pathsMatch(_ a: String, _ b: String) -> Bool {
    // treat "/api" and "/api/" as the same
    let norm: (String) -> String = { p in p.hasSuffix("/") ? String(p.dropLast()) : p }
    return norm(a) == norm(b)
}

extension Stubs {
    @discardableResult
    static func installJSONStub(
        urlString: String,
        file: String,
        contentType: String = "application/json",
        delegate: MockMageServerDelegate,
        onHit: (() -> Void)? = nil
    ) -> HTTPStubsDescriptor {
        let u = URL(string: urlString)!
        
        return HTTPStubs.stubRequests(passingTest: { req in
            guard let url = req.url else { return false }
            
            return url.host == u.host && _pathsMatch(url.path, u.path)
        }) { req in
            delegate.urlCalled(req.url, method: req.httpMethod)
            onHit?() // Fulfill caller's expectation
            
            guard let path = Bundle(for: _AuthTestKitBundleSentinel.self)
                .path(forResource: file, ofType: nil) else {
                assertionFailure("Fixture '\(file)' not found in test bundle")
                return HTTPStubsResponse(data: Data(), statusCode: 500, headers: nil)
            }
            
            return HTTPStubsResponse(
                fileAtPath: path,
                statusCode: 200,
                headers: ["Content-Type": contentType]
            ).responseTime(0.01)
        }
    }
}

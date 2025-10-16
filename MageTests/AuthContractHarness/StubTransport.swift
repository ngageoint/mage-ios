//
//  StubTransport.swift
//  MAGE
//
//  Created by Brent Michalski on 10/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

/// Loads canned responses from test bundle so we can verify the harness compiles and runs.
final class StubPerformer: LegacyAuthPerformer, NewAuthPerformer {
    enum Fixture: String {
        case login_ok = "login_ok.json"
        case login_invalid = "login_invalid.json"
        case signup_conflict = "signup_conflict.json"
        case captcha_401 = "captcha_401.json"
        case change_ok = "change_ok.json"
        case change_401 = "change_401.json"
    }
    
    let mapping: [String: (status: Int, file: Fixture)]
    
    init(mapping: [String: (Int, Fixture)]) {
        self.mapping = mapping
    }
    
    func perform(_ endpoint: AuthEndpoint) async -> HTTPResponse {
        let req = endpoint.request
        let key = "\(req.method) \(req.path)"
        guard let m = mapping[key] else { return .init(status: 501, body: nil, headers: [:]) }
        return .init(status: m.status, body: Self.load(m.file.rawValue), headers: [:])
    }
    
    private static func load(_ name: String) -> Data? {
        let bundle = Bundle(for: StubPerformer.self)
        let url = bundle.url(forResource: name, withExtension: nil)!
        return try? Data(contentsOf: url)
    }
}

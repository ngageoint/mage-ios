//
//  LogoutService {.swift
//  MAGE
//
//  Created by Brent Michalski on 10/13/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

@MainActor
struct LogoutService {
    static func logout(baseURL: URL, session: URLSession = .shared) async {
        var req = URLRequest(url: baseURL.appendingPathComponent("api/logout"))
        req.httpMethod = "POST"
        req.addValue("application/json", forHTTPHeaderField: "Accept")
        do { _ = try await session.data(for: req) } catch {
            print("Failed to fully logout. Error: \(error.localizedDescription)")
        }
    }
}

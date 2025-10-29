//
//  URL+AccessToken.swift
//  MAGE
//
//  Created by Brent Michalski on 8/12/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

enum AccessTokenURL {
    /// Returns `url` with `access_token` appended and preserves the existing query
    /// `token` defaults to the stored password token, but you can override in tests.
    static func tokenized(_ url: URL,
                          token: String = StoredPassword.retrieveStoredToken()) -> URL {
        var comps = URLComponents(url: url, resolvingAgainstBaseURL: false)
        var items = comps?.queryItems ?? []
        items.append(URLQueryItem(name: "access_token", value: token))
        comps?.queryItems = items
        return comps?.url ?? url
    }
}

//
//  RESTAuthCommon.swift
//  Authentication
//
//  Created by Brent Michalski on 9/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

struct HTTP {
    static func postJSON(_ url: URL,
                         body: [String: Any],
                         completion: @escaping (Int, Data?, Error?) -> Void) {
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        URLSession.shared.dataTask(with: req) { data, resp, err in
            let code = (resp as? HTTPURLResponse)?.statusCode ?? -1
            completion(code, data, err)
        }.resume()
    }
}

extension Dictionary where Key == AnyHashable, Value == Any {
    func string(_ key: String) -> String? { self[key] as? String }
}



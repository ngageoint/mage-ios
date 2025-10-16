//
//  HTTPRequest.swift
//  MAGE
//
//  Created by Brent Michalski on 10/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation

struct HTTPRequest {
    var method: String
    var path: String
    var body: Data?
    var headers: [String:String] = [:]
}

struct HTTPResponse: Equatable {
    var status: Int
    var body: Data?
    var headers: [String:String] = [:]
}

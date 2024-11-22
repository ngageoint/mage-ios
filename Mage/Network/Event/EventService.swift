//
//  EventService.swift
//  MAGETests
//
//  Created by Dan Barela on 9/3/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Alamofire

enum EventService: URLRequestConvertible {
    case fetchEvents
    
    var method: HTTPMethod {
        switch self {
        case .fetchEvents:
            return .get
        }
    }
    
    var path: String {
        switch self {
        case .fetchEvents:
            return "/api/events"
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .fetchEvents:
            return nil
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        guard let url = MageServer.baseURL() else {
            throw ObservationError.invalidServer
        }

        var urlRequest = URLRequest(url: url.appendingPathComponent(path))
        urlRequest.httpMethod = method.rawValue

        urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)

        return urlRequest
    }
}

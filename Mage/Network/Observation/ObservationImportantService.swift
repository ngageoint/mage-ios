//
//  ObservationImportantService.swift
//  MAGE
//
//  Created by Dan Barela on 8/5/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Alamofire

enum ObservationImportantService: URLRequestConvertible {
    case pushImportant(eventId: NSNumber, observationRemoteId: String, reason: String?)
    case deleteImportant(eventId: NSNumber, observationRemoteId: String)
    
    var method: HTTPMethod {
        switch self {
        case .pushImportant:
            return .put
        case .deleteImportant:
            return .delete
        }
    }
    
    var path: String {
        switch self {
        case .pushImportant(let eventId, let observationRemoteId, _):
            return "/api/events/\(eventId)/observations/\(observationRemoteId)/important"
        case .deleteImportant(let eventId, let observationRemoteId):
            return "/api/events/\(eventId)/observations/\(observationRemoteId)/important"
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .pushImportant(_, _, let reason): //(let eventId, let date):
            // we cannot reliably query for asams that occured after the date we have because
            // records can be inserted with an occurance date in the past
            // we have to query for all records all the time
            let params: [String: Any] = [
                ObservationImportantKey.description.key: reason ?? NSNull()
            ]
            return params
        case .deleteImportant(_, _):
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

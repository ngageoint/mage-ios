//
//  ObservationFavoriteService.swift
//  MAGE
//
//  Created by Dan Barela on 8/6/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Alamofire

enum ObservationFavoriteService: URLRequestConvertible {
    case pushFavorite(eventId: NSNumber, observationRemoteId: String)
    case deleteFavorite(eventId: NSNumber, observationRemoteId: String)
    
    var method: HTTPMethod {
        switch self {
        case .pushFavorite:
            return .put
        case .deleteFavorite:
            return .delete
        }
    }
    
    var path: String {
        switch self {
        case .pushFavorite(let eventId, let observationRemoteId):
            return "/api/events/\(eventId)/observations/\(observationRemoteId)/favorite"
        case .deleteFavorite(let eventId, let observationRemoteId):
            return "/api/events/\(eventId)/observations/\(observationRemoteId)/favorite"
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .pushFavorite(_, _):
            return nil
        case .deleteFavorite(_, _):
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

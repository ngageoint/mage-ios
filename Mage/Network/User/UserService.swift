//
//  UserService.swift
//  MAGE
//
//  Created by Dan Barela on 8/21/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Alamofire

enum UserService: URLRequestConvertible {
    case uploadAvatar(imageData: Data)
    case fetchMyself
    
    var method: HTTPMethod {
        switch self {
        case .uploadAvatar(_):
            return .put
        case .fetchMyself:
            return .get
        }
    }
    
    var path: String {
        switch self {
        case .uploadAvatar(_):
            return "/api/users/myself"
        case .fetchMyself:
            return "/api/users/myself"
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .uploadAvatar(_):
            return nil
        case .fetchMyself:
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

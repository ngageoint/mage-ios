//
//  SettingsService.swift
//  MAGE
//

import Foundation
import Alamofire

enum SettingsService: URLRequestConvertible {
    case fetchMapSettings
    
    var method: HTTPMethod {
        switch self {
        case .fetchMapSettings:
            return .get
        }
    }
    
    var path: String {
        switch self {
        case .fetchMapSettings:
            return "/api/settings/map"
        }
    }
    
    var parameters: Parameters? {
        switch self {
        case .fetchMapSettings:
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

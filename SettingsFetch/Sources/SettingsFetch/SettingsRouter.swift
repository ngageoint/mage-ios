// 
//     
//  SettingsRouter.swift
//  SettingsFetch
//
// 


import Foundation
import APIRouter
import Alamofire

struct SettingsRouter: APIRouter {
    let baseURL: URL
    
    enum Endpoint {
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
    }

    let endpoint: Endpoint

    var path: String { endpoint.path }
    var method: HTTPMethod { endpoint.method }
    var parameters: Parameters? { endpoint.parameters }
    
    func asURLRequest() throws -> URLRequest {
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent(path))
        urlRequest.httpMethod = method.rawValue

        urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)

        return urlRequest
    }
}

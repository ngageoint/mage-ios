//
//  LocationFetchRouter.swift
//  LocationFetch
//
//


import Foundation
import Alamofire
import APIRouter

struct LocationFetchRouter: APIRouter {
    let baseURL: URL

    enum Endpoint {
        case fetchLocations(eventId: NSNumber, lastLocationDate: Date?)
        
        var method: HTTPMethod {
            switch self {
            case .fetchLocations:
                return .get
            }
        }
        
        var path: String {
            switch self {
            case .fetchLocations(let eventId, _):
                return "/api/events/\(eventId)/locations/users"
            }
        }
        
        var parameters: Parameters? {
            switch self {
            case .fetchLocations(_, let lastLocationDate):
                // only fetch the last location
                var parameters: [String: Sendable] = [
                    "limit" : "1"
                ]
                if let lastLocationDate {
                    parameters["startDate"] = ISO8601DateFormatter.string(from: lastLocationDate, timeZone: TimeZone(secondsFromGMT: 0)!, formatOptions: [.withDashSeparatorInDate, .withFullDate, .withFractionalSeconds, .withTime, .withColonSeparatorInTime, .withTimeZone])
                }
                return parameters
            }
        }
        
        var headers: [HTTPHeader]? {
            switch self {
            default:
                return nil
            }
        }
    }
    
    let endpoint: Endpoint

    var path: String { endpoint.path }
    var method: HTTPMethod { endpoint.method }
    var parameters: Parameters? { endpoint.parameters }
    var headers: [HTTPHeader]? { endpoint.headers }
    
    func asURLRequest() throws -> URLRequest {
        var urlRequest = URLRequest(url: baseURL.appendingPathComponent(path))
        urlRequest.httpMethod = method.rawValue

        switch method {
        case .post, .put:
            urlRequest = try JSONEncoding.default.encode(urlRequest, with: parameters)
        default:
            urlRequest = try URLEncoding.default.encode(urlRequest, with: parameters)
        }
        
        for header in headers ?? [] {
            urlRequest.headers.add(header)
        }

        return urlRequest
    }
}

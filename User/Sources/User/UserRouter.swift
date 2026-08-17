//
//  UserFetchRouter.swift
//  UserFetch
//
//

import Foundation
import Alamofire
import APIRouter
import ServerDTO

public struct UserRouter: APIRouter {
    public init(
        baseURL: URL,
        endpoint: Endpoint
    ) {
        self.baseURL = baseURL
        self.endpoint = endpoint
    }
    
    public let baseURL: URL

    public enum Endpoint: Sendable {
        case fetchEventUsers(eventId: NSNumber)
        case fetchMyself
        case fetchUser(remoteId: UserID)
        
        var method: HTTPMethod {
            switch self {
            case .fetchEventUsers:
                return .get
            case .fetchMyself:
                return .get
            case .fetchUser:
                return .get
            }
        }
        
        var path: String {
            switch self {
            case .fetchEventUsers(let eventId):
                return "/api/events/\(eventId)/users"
            case .fetchMyself:
                return "/api/users/myself"
            case .fetchUser(let remoteId):
                return "/api/users/\(remoteId)"
            }
        }
        
        var parameters: Parameters? {
            switch self {
            case .fetchEventUsers(_):
                return nil
            case .fetchMyself:
                return nil
            case .fetchUser:
                return nil
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

    public var path: String { endpoint.path }
    public var method: HTTPMethod { endpoint.method }
    public var parameters: Parameters? { endpoint.parameters }
    public var headers: [HTTPHeader]? { endpoint.headers }
    
    public func asURLRequest() throws -> URLRequest {
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

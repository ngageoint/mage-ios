import Foundation
import Alamofire
import APIRouter

struct EventFetchRouter: APIRouter {
    let baseURL: URL
    
    init(baseURL: URL, endpoint: Endpoint) {
        self.baseURL = baseURL
        self.endpoint = endpoint
    }

    enum Endpoint: Sendable {
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

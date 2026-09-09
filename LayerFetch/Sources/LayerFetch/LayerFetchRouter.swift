import Foundation
import Alamofire
import ServerDTO
import APIRouter

struct LayerFetchRouter: APIRouter {
    let baseURL: URL
    
    enum Endpoint {
        case fetchLayers(eventID: EventID)
        case fetchStaticLayerData(eventID: EventID, layerID: LayerID)
        
        var method: HTTPMethod {
            switch self {
            case .fetchLayers:
                return .get
            case .fetchStaticLayerData:
                return .get
            }
        }
        
        var path: String {
            switch self {
            case .fetchLayers(let eventID):
                return "/api/events/\(eventID.intValue)/layers"
            case .fetchStaticLayerData(let eventID, let layerID):
                return "/api/events/\(eventID.intValue)/layers/\(layerID.rawValue)/features"
            }
        }
        
        var parameters: Parameters? {
            switch self {
            case .fetchLayers:
                return nil
            case .fetchStaticLayerData:
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

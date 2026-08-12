import Foundation
import Alamofire

public protocol APIRouter: URLRequestConvertible {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var parameters: Parameters? { get }
}

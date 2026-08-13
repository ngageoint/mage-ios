// 
//     
//  TokenAPISessionImpl.swift
//  MAGE
//
// 


public struct TokenAPISessionImpl: TokenAPISession {
    let baseURL: URL
    let loginType: String?
    let notificationCenter: NotificationCenter
    let trustManager: DynamicServerTrustManager = DynamicServerTrustManager(
        evaluators: [:]
    )
    
    public let session: Session

    public init(
        baseURL: URL,
        loginType: String?,
        additionalHeaders: [String: String]? = nil,
        notificationCenter: NotificationCenter = .default
    ) {
        self.loginType = loginType
        self.baseURL = baseURL
        self.notificationCenter = notificationCenter
        
        trustManager.addTrustedHost("osm-nominatim.gs.mil")
        if let host = baseURL.host() {
            trustManager.addTrustedHost(host)
        }
        let configuration = URLSessionConfiguration.af.default
        configuration.httpMaximumConnectionsPerHost = 4
        configuration.timeoutIntervalForRequest = 120
        configuration.httpAdditionalHeaders = additionalHeaders
        self.session = Session(
            configuration: configuration,
            interceptor: TokenAPIBearerRequestAdapter(),
            serverTrustManager: trustManager
        )
    }
    
    public func validateResponse() -> DataRequest.Validation {
        { request, response, data in
            if self.loginType == "offline" {
                // if the user was logged in offline and a request makes it, we should tell them that they can try to login again
                if (response.statusCode == 401) {
                    notificationCenter.post(name: .ServerContactedAfterOfflineLogin, object: response)
                    return DataRequest.ValidationResult.failure(GeneralError.expiredToken)
                }
            }
            // if the user was online and the token was expired ie 401 we should force them to the login screen
            else if (response.statusCode == 401) {
                Task {
                    await self.expireToken()
                    notificationCenter.post(name: .APITokenExpiredNotification, object: response)
                }
                return DataRequest.ValidationResult.failure(GeneralError.expiredToken)
            }
            
            return DataRequest.ValidationResult.success(())
        }
    }
    
    public func validateDownloadResponse() -> DownloadRequest.Validation {
        { request, response, fileUrl in
            guard let request = request, let url = request.url else {
                return DownloadRequest.ValidationResult.success(())
            }
            
            NSLog("Request URL: \(url)")
            NSLog("Request Status: \(response.statusCode)")
            
            if loginType == "offline" {
                // if the user was logged in offline and a request makes it, we should tell them that they can try to login again
                if (response.statusCode == 401) {
                    notificationCenter.post(name: .ServerContactedAfterOfflineLogin, object: response)
                    return DownloadRequest.ValidationResult.failure(GeneralError.expiredToken)
                }
            }
            // if the user was online and the token was expired ie 401 we should force them to the login screen
            else if (response.statusCode == 401) {
                Task {
                    await self.expireToken()
                    notificationCenter.post(name: .APITokenExpiredNotification, object: response)
                }
                return DownloadRequest.ValidationResult.failure(GeneralError.expiredToken)
            }
            
            return DownloadRequest.ValidationResult.success(())
        }
    }
    
    public func expireToken() async {
        StoredPassword.clearToken()
    }
    
    public func clearToken() async {
        StoredPassword.clearToken()
    }
    
    public func setToken(_ token: String?) async {
        if let token = token {
            _ = StoredPassword.persistToken(toKeyChain: token)
        } else {
            StoredPassword.clearToken()
        }
    }
    
    public func addTrustedHost(_ host: String) {
        trustManager.addTrustedHost(host)
    }
    
}

import Alamofire
import APIRouter

public enum GeneralError: Error, Equatable {
    case expiredToken
    case coreDataUnavailable
    case writeContextUnavailable
    case noEventProvided
    case serverError(error: String)
    case noSessionExists
}

extension GeneralError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .expiredToken:
            return "Token is expired."
        case .coreDataUnavailable:
            return "Core Data is unavailable."
        case .writeContextUnavailable:
            return "Write context is unavailable."
        case .noEventProvided:
            return "No Event ID was provided."
        case .serverError(let error):
            return error
        case .noSessionExists:
            return "No Server Session Exists"
            
        }
    }
}

extension GeneralError: Identifiable {
    public var id: String? {
        errorDescription
    }
}

extension Notification.Name {
    public static let APITokenExpiredNotification = Notification.Name("mil.nga.giat.mage.token.expired")
    public static let ServerContactedAfterOfflineLogin = Notification.Name("mil.nga.mage.server.contacted")
}

final class TokenAPIBearerRequestAdapter: RequestInterceptor {
    
    public func adapt(_ urlRequest: URLRequest, for session: Alamofire.Session, completion: @Sendable @escaping (Result<URLRequest, any Error>) -> Void) {
        Task { [urlRequest] in
            var urlRequest = urlRequest
            if urlRequest.allHTTPHeaderFields?["Authorization"] == nil, let token = StoredPassword.retrieveStoredToken() {
                urlRequest.headers.add(.authorization(bearerToken: token))
            }
            
            completion(.success(urlRequest))
        }
    }
}

import Synchronization

final class DynamicServerTrustManager: ServerTrustManager, @unchecked Sendable {
    // ensure the set of hosts is protected
    let trustedHosts: Mutex<Set<String>> = Mutex(Set<String>())
    
    override func serverTrustEvaluator(forHost host: String) throws -> ServerTrustEvaluating? {
        return try trustedHosts.withLock { set in
            if set.contains(host) {
                return DefaultTrustEvaluator(validateHost: true)
            }
            return try super.serverTrustEvaluator(forHost: host)
        }
    }
    
    func addTrustedHost(_ host: String) {
        print("Add trusted host \(host)")
        _ = trustedHosts.withLock { set in
            set.insert(host) // Safely add to the set
        }
    }
    
}

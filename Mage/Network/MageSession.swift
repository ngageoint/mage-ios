//
//  MageSession.swift
//  MAGE
//
//  Created by Daniel Barela on 4/15/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Alamofire
import Combine

enum MageError: Error {
    case expiredToken
}

extension MageError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .expiredToken:
            return "Token is expired."
        }
    }
}

extension MageError: Identifiable {
    var id: String? {
        errorDescription
    }
}


class MageBearerRequestAdapter: RequestInterceptor {
    func adapt(_ urlRequest: URLRequest, for session: Alamofire.Session, completion: @escaping (Result<URLRequest, any Error>) -> Void) {
        var urlRequest = urlRequest
        urlRequest.headers.add(.authorization(bearerToken: MageSessionManager.shared().getToken()))
        completion(.success(urlRequest))
    }
}

class MageSession {
    static let shared = MageSession()

    var cancellable = Set<AnyCancellable>()
    var baseServerUrl: String?

    let validateMageResponse: DataRequest.Validation = { request, response, data in
        guard let request = request, let url = request.url else {
            return DataRequest.ValidationResult.success(())
        }

        NSLog("Request URL: \(url)")
        NSLog("Request Status: \(response.statusCode)")

        // if the url path did not require a token, return success
        let path = url.path()
        if path.contains("signin") ||
            path.contains("authorize") ||
            path.contains("devices") ||
            path.contains("password") ||
            path.contains("auth/token")
        {
            return DataRequest.ValidationResult.success(())
        }

        // if the token expired, kick the user out and make them log in again
        // isTokenExpired, checks, and also sends a notification
        if UserUtility.singleton.isTokenExpired {
            return DataRequest.ValidationResult.failure(MageError.expiredToken)
        }

        if UserDefaults.standard.loginType == "offline" {
            // if the user was logged in offline and a request makes it, we should tell them that they can try to login again
            if (response.statusCode == 401) {
                NotificationCenter.default.post(name: .MAGEServerContactedAfterOfflineLogin, object: response)
                return DataRequest.ValidationResult.failure(MageError.expiredToken)
            }
        }
        // if the user was online and the token was expired ie 401 we should force them to the login screen
        else if (response.statusCode == 401) {
            UserUtility.singleton.expireToken()
            NotificationCenter.default.post(name: .MAGETokenExpiredNotification, object: response)
            return DataRequest.ValidationResult.failure(MageError.expiredToken)
        }

        return DataRequest.ValidationResult.success(())
    }

    init() {
        baseServerUrl = UserDefaults.standard.baseServerUrl
        // set the initial session
        if let urlString = UserDefaults.standard.baseServerUrl,
           let url = URL(string: urlString),
           let host = url.host()
        {
            let configuration = URLSessionConfiguration.af.default
            configuration.httpMaximumConnectionsPerHost = 4
            configuration.timeoutIntervalForRequest = 120
            let manager = ServerTrustManager(evaluators: [
                host: DefaultTrustEvaluator(validateHost: true),
                "osm-nominatim.gs.mil": DefaultTrustEvaluator(validateHost: true)
            ])

            self._session = Session(configuration: configuration, interceptor: MageBearerRequestAdapter(), serverTrustManager: manager)
        } else {
            self._session = Session()
        }


        // when the server url changes, recreate the session
        UserDefaults.standard.publisher(for: \.baseServerUrl)
            .receive(on: RunLoop.main)
            .sink { [weak self] urlString in
                guard let self = self,
                      self.baseServerUrl != urlString,
                      let urlString = urlString,
                      let url = URL(string: urlString),
                      let host = url.host()
                else {
                    return
                }
                self.baseServerUrl = urlString
                let configuration = URLSessionConfiguration.af.default
                configuration.httpMaximumConnectionsPerHost = 4
                configuration.timeoutIntervalForRequest = 120
                let manager = ServerTrustManager(evaluators: [
                    host: DefaultTrustEvaluator(validateHost: true),
                    "osm-nominatim.gs.mil": DefaultTrustEvaluator(validateHost: true)
                ])

                self._session = Session(configuration: configuration, interceptor: MageBearerRequestAdapter(), serverTrustManager: manager)
            }
            .store(in: &cancellable)
    }

    var _session: Session

    var session: Session {
        get {
            return _session
        }
    }
    
    lazy var backgroundLoadQueue: OperationQueue = {
        var queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        queue.name = "Data load queue"
        return queue
    }()
}

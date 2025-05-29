//
//  ObservationService.swift
//  MAGE
//
//  Created by Daniel Barela on 4/15/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Alamofire

enum ObservationError: Error {
    case noEvent
    case invalidServer
}

extension ObservationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .noEvent:
            return "No current event is set."
        case .invalidServer:
            return "Invalid MAGE server specified"
        }
    }
}

extension ObservationError: Identifiable {
    var id: String? {
        errorDescription
    }
}

enum ObservationService: URLRequestConvertible {
    case getObservations(eventId: Int, date: Date?)

    var method: HTTPMethod {
        switch self {
        case .getObservations:
            return .get
        }
    }

    var path: String {
        switch self {
        case .getObservations(let eventId, let date):
            return "/api/events/\(eventId)/observations"
        }
    }

    var parameters: Parameters? {
        switch self {
        case .getObservations(let eventId, let date):
            // we cannot reliably query for asams that occured after the date we have because
            // records can be inserted with an occurance date in the past
            // we have to query for all records all the time
            var params = [
                "sort": "lastModified+DESC"
            ]
            if let date = date {
                params["startDate"] = ISO8601DateFormatter.string(from: date, timeZone: TimeZone(secondsFromGMT: 0)!, formatOptions: [.withDashSeparatorInDate, .withFullDate, .withFractionalSeconds, .withTime, .withColonSeparatorInTime, .withTimeZone])
            }
            return params
        }
    }

    // MARK: URLRequestConvertible

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

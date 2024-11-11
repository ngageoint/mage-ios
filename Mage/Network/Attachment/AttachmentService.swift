//
//  AttachmentService.swift
//  MAGE
//
//  Created by Dan Barela on 11/8/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import Alamofire

enum AttachmentService: URLRequestConvertible {
    case deleteAttachment(eventId: Int, observationRemoteId: String, attachmentRemoteId: String)
    case uploadAttachment(eventId: Int, observationRemoteId: String, attachmentRemoteId: String)

    var method: HTTPMethod {
        switch self {
        case .deleteAttachment:
            return .delete
        case .uploadAttachment:
            return .put
        }
    }

    var path: String {
        switch self {
        case .deleteAttachment(let eventId, let observationRemoteId, let attachmentRemoteId):
            return "api/events/\(eventId)/observations/\(observationRemoteId)/attachments/\(attachmentRemoteId)"
        case .uploadAttachment(let eventId, let observationRemoteId, let attachmentRemoteId):
            return "api/events/\(eventId)/observations/\(observationRemoteId)/attachments/\(attachmentRemoteId)"
        }
    }

    var parameters: Parameters? {
        switch self {
        case .deleteAttachment(_, _, _):
            return nil
        case .uploadAttachment(_, _, _):
            return nil
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

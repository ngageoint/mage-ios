//
//  LocationDTOContext.swift
//  LocationFetch
//
//

import Foundation
import ServerDTO
import FetchOperation

public protocol LocationDTOContext: Sendable {
    var locationDTO: [UserLocationDTO] { get set }
}

public protocol LocationSaveResultContext: Sendable {
    var locationSaveResult: LocationSaveResult? { get set }
}

public struct LocationPipelineContext: LocationDTOContext, LocationSaveResultContext, URLRequestContext {
    public init(eventID: EventID) {
        self.eventID = eventID
    }
    public var locationSaveResult: LocationSaveResult?
    
    public let eventID: EventID
    public var newestLocationDate: Date?
    public var locationDTO: [UserLocationDTO] = []
    public var urlRequest: URLRequest?
}

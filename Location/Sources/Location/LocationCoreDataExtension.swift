//
//  File.swift
//  Location
//
//

import Foundation
import Persistence
import ServerDTO
import CodableExtensions

public extension Location {
    func populate(dto: LocationDTO) {
        remoteId = dto.id
        type = dto.type
        if let eventId = dto.eventId {
            self.eventId = NSNumber(value:eventId)
        }
        
        properties = dto.properties?.dictionary as? [AnyHashable : Any]
        timestamp = dto.timestamp;
        geometryData = dto.geometryData
    }
}

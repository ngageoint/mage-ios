//
//  LocationDTO.swift
//  ServerDTO
//
//


import Foundation
import SimpleFeatures
import SimpleFeaturesGeoJSON
import ExceptionCatcher
import SendableExtensions

// periphery:ignore - DTO is meant to reflect the servers
public struct LocationDTO: Decodable, Sendable {
    private enum Keys : String, CodingKey {
        case _id
        case type
        case eventId
        case properties
        case timestamp
        case geometry
        case userId
        case teamIds
        
        var key: String {
            return self.rawValue
        }
    }
    
    public let id: String?
    public let userId: String?
    public let teamIds: [String]?
    public let type: String?
    public let eventId: Int?
    public let timestamp: Date?
    public let properties: LocationPropertiesDTO?
    let sendableGeometry: [String: SendableValue]?
    public var geometry: [String: Any]? {
        sendableGeometry?.toAnyValues()
    }
    public var geometryData: Data? {
        guard let json = geometry else {
            return nil;
        }
        var sfggeometry: SFGGeometry?;
        do {
            try ExceptionCatcher.catch {
                sfggeometry = SFGFeatureConverter.tree(toGeometry: json)
            }
        }
        catch {
            ServerDTOPackage.logger.error("Location Geometry Parsing error: \(error)")
        }
        if let parsed = sfggeometry?.geometry() {
            return SFGeometryUtils.encode(parsed)
        }
        return nil
    }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: Keys.self)
        self.id = try? values.decode(String.self, forKey: ._id)
        self.userId = try? values.decode(String.self, forKey: .userId)
        self.teamIds = try? values.decode([String].self, forKey: .teamIds)
        self.type = try? values.decode(String.self, forKey: .type)
        self.eventId = try? values.decode(Int.self, forKey: .eventId)
        self.properties = try? values.decode(LocationPropertiesDTO.self, forKey: .properties)
        self.timestamp = properties?.timestamp
        self.sendableGeometry = try? values.decode([String: SendableValue].self, forKey: .geometry)
    }
    
    static let dateFormatter: Date.ISO8601FormatStyle = {
        var style = Date.ISO8601FormatStyle.iso8601
            .year()
            .month()
            .day()
            .timeZone(separator: .omitted)
            .time(includingFractionalSeconds: true)
            .timeSeparator(.colon)
            .dateSeparator(.dash)
        style.timeZone = .gmt
        return style
    }()
}

// this is not all of the properties returned, just the ones we currently care about, parse more if we want to show more
public struct LocationPropertiesDTO: Codable, Sendable {
    private enum Keys : String, CodingKey {
        case altitude
        case accuracy
        case timestamp
    }
    
    public let altitude: Double?
    public let accuracy: Double?
    public let timestamp: Date?
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: Keys.self)
        self.altitude = try? values.decode(Double.self, forKey: .altitude)
        self.accuracy = try? values.decode(Double.self, forKey: .accuracy)
        if let timestampString = try? values.decode(String.self, forKey: .timestamp) {
            var parsedDate: Date?
            if let date = try? LocationDTO.dateFormatter.parse(timestampString) {
                parsedDate = date
            }
            self.timestamp = parsedDate
        } else {
            self.timestamp = nil
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container.encodeIfPresent(self.altitude, forKey: .altitude)
        try container.encodeIfPresent(self.accuracy, forKey: .accuracy)
        if let timestamp {
            try container.encodeIfPresent(LocationDTO.dateFormatter.format(timestamp), forKey: .timestamp)
        }
    }
}

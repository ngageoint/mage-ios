
import Foundation
import SendableExtensions

public struct StaticLayerFeatureCollectionDTO: Codable, Sendable {
    public var type: String
    public var features: [StaticLayerFeatureDTO]
}

public struct GeoJSONGeometryDTO: Codable, Sendable {
    public let type: String
    public let coordinates: Coordinates
}

public enum Coordinates: Codable, Sendable {
    case point([Double])
    case line([[Double]])
    case polygon([[[Double]]])
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let point = try? container.decode([Double].self) {
            self = .point(point)
            return
        }
        
        if let line = try? container.decode([[Double]].self) {
            self = .line(line)
            return
        }
        
        if let polygon = try? container.decode([[[Double]]].self) {
            self = .polygon(polygon)
            return
        }
        
        throw DecodingError.typeMismatch(
            Coordinates.self,
            .init(
                codingPath: decoder.codingPath,
                debugDescription: "Expected either [Double] or [[Double]]"
            )
        )
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .point(let point):
            try container.encode(point)
        case .line(let line):
            try container.encode(line)
        case .polygon(let polygon):
            try container.encode(polygon)
        }
    }
}

// periphery:ignore - DTO is meant to reflect the server
public struct StaticLayerFeatureDTO: Codable, Sendable {
    private enum Keys : String, CodingKey {
        case type
        case geometry
        case properties
        case id
    }
    public var type: String?
    public var geometry: GeoJSONGeometryDTO?
    public var properties: [String: SendableValue]?
    public var id: String?
    
    public func isEqualTo(_ other: StaticLayerFeatureDTO) -> Bool {
        return self.id == other.id
    }
    
    public static func == (lhs: StaticLayerFeatureDTO, rhs: StaticLayerFeatureDTO) -> Bool {
        lhs.isEqualTo(rhs)
    }
    
    public init() {
        
    }
}

extension StaticLayerFeatureDTO {
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: Keys.self)
        self.type = try? values.decode(String.self, forKey: .type)
        self.geometry = try? values.decode(GeoJSONGeometryDTO.self, forKey: .geometry)
        self.properties = try? values.decode([String: SendableValue].self, forKey: .properties)
        self.id = try? values.decode(String.self, forKey: .id)
    }
}

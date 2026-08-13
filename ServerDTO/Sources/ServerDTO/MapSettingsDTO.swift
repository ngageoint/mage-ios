// 
//     
//  MapSettingsDTO.swift
//  ServerDTO
//
// 


// periphery:ignore - DTO is meant to reflect the server
public struct MapSettingsDTO: Codable, Sendable {
    private enum Keys: String, CodingKey {
        case mobileNominatimUrl
        case mobileSearchType
    }
    public let mobileNominatimUrl: String?
    public let mobileSearchType: MapSearchType?
    
    public init(mobileNominatimUrl: String?, mobileSearchType: MapSearchType?) {
        self.mobileNominatimUrl = mobileNominatimUrl
        self.mobileSearchType = mobileSearchType
    }
}

extension MapSettingsDTO {
    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: Keys.self)
        self.mobileNominatimUrl = try? values.decode(String.self, forKey: .mobileNominatimUrl)
        let serverSearchType = try? values.decode(String.self, forKey: .mobileSearchType)
        if let raw = serverSearchType {
            mobileSearchType = MapSearchType(raw)
        } else {
            ServerDTOPackage.logger.warning("Missing mobileSearchType")
            mobileSearchType = MapSearchType.none
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Keys.self)
        try container
            .encode(mobileSearchType?.serverValue, forKey: .mobileSearchType)
        try container.encode(mobileNominatimUrl, forKey: .mobileNominatimUrl)
    }
}

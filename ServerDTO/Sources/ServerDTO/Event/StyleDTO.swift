import CodableExtensions

public struct StyleDTO: Codable, Sendable {
    public init(strokeWidth: Double? = nil, strokeOpacity: Double? = nil, stroke: String? = nil, fillOpacity: Double? = nil, fill: String? = nil, fieldStyles: [String : StyleDTO]? = nil) {
        self.strokeWidth = strokeWidth
        self.strokeOpacity = strokeOpacity
        self.stroke = stroke
        self.fillOpacity = fillOpacity
        self.fill = fill
        self.fieldStyles = fieldStyles
    }
    
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case strokeWidth
        case strokeOpacity
        case stroke
        case fillOpacity
        case fill
    }
    
    public let strokeWidth: Double?
    public let strokeOpacity: Double?
    public let stroke: String?
    public let fillOpacity: Double?
    public let fill: String?
    public let fieldStyles: [String: StyleDTO]?
}

public extension StyleDTO {
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        strokeWidth = try? container.decode(Double.self, forKey: .strokeWidth)
        strokeOpacity = try? container.decode(Double.self, forKey: .strokeOpacity)
        stroke = try? container.decode(String.self, forKey: .stroke)
        fillOpacity = try? container.decode(Double.self, forKey: .fillOpacity)
        fill = try? container.decode(String.self, forKey: .fill)

        // Handling extra keys
        var tempExtraData: [String: StyleDTO] = [:]
        let allKeys = try decoder.container(keyedBy: DynamicCodingKey.self).allKeys
        for key in allKeys {
            if !CodingKeys.allCases.contains(where: { $0.stringValue == key.stringValue }) {
                // Decode the extra key's value and store it
                // (Requires a way to handle dynamic types, e.g., using AnyCodable)
                let nestedContainer = try decoder.container(keyedBy: DynamicCodingKey.self)
                if let value = try? nestedContainer.decode(StyleDTO.self, forKey: key) {
                    tempExtraData[key.stringValue] = value
                }
            }
        }
        fieldStyles = tempExtraData
    }
}

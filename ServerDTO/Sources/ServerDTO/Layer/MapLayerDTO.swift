import Foundation
import SendableExtensions

// periphery:ignore - DTO is meant to reflect the server
public struct MapLayerDTO: Codable, Sendable {
    public init(
        remoteId: LayerID = LayerID(-1),
        name: String? = nil,
        type: String? = nil,
        url: String? = nil,
        sendableFile: [String : SendableValue]? = nil,
        layerDescription: String? = nil,
        state: String? = nil,
        base: Bool = false,
        eventId: EventID = EventID(-1),
        sendableOptions: [String : SendableValue]? = nil,
        format: String? = nil
    ) {
        self.remoteId = remoteId
        self.name = name
        self.type = type
        self.url = url
        self.sendableFile = sendableFile
        self.layerDescription = layerDescription
        self.state = state
        self.base = base
        self.eventId = eventId
        self.sendableOptions = sendableOptions
        self.format = format
    }
    
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case type
        case url
        case file
        case wms
        case format
        case features
        case layerDescription
        case description
        case state
        case remoteId
        case eventId
        case tables
        case base
    }
    
    private enum StaticLayerCodingKeys: String, CodingKey {
        case properties
        case style
        case iconStyle
        case icon
        case href
        case id
    }
    
    public var remoteId: LayerID = LayerID(-1)
    public var name: String?
    public var type: String?
    public var url: String?
    public var sendableFile: [String: SendableValue]?
    public var file: [String: Any]? {
        sendableFile?.toAnyValues()
    }
    public var layerDescription: String?
    public var state: String?
    public var base: Bool = false
    public var eventId: EventID = EventID(-1)
    public var sendableOptions: [String: SendableValue]?
    public var options: [String: Any]? {
        get {
            sendableOptions?.toAnyValues()
        }
        set {
            sendableOptions = newValue?.toSendableValues()
        }
    }
    public var format: String?
    
    public func isEqualTo(_ other: MapLayerDTO) -> Bool {
        return self.remoteId == other.remoteId
    }
    
    public static func == (lhs: MapLayerDTO, rhs: MapLayerDTO) -> Bool {
        lhs.isEqualTo(rhs)
    }
    
    public init() { }
    
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.remoteId = (try? values.decode(LayerID.self, forKey: .id)) ?? LayerID(-1)
        self.name = try? values.decode(String.self, forKey: .name)
        self.type = try? values.decode(String.self, forKey: .type)
        self.url = try? values.decode(String.self, forKey: .url)
        self.sendableFile = try? values.decode([String: SendableValue].self, forKey: .file)
        self.layerDescription = try? values.decode(String.self, forKey: .description)
        self.state = try? values.decode(String.self, forKey: .state)
        self.base = (try? values.decode(Bool.self, forKey: .base)) ?? false
        self.sendableOptions = try? values.decode([String: SendableValue].self, forKey: .wms)
        self.format = try? values.decode(String.self, forKey: .format)
        self.eventId = (try? values.decode(EventID.self, forKey: .eventId)) ?? EventID(-1)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(remoteId, forKey: .remoteId)
        try? container.encode(name, forKey: .name)
        try? container.encode(type, forKey: .type)
        try? container.encode(url, forKey: .url)
        try? container.encode(sendableFile, forKey: .file)
        try? container.encode(layerDescription, forKey: .description)
        try? container.encode(state, forKey: .state)
        try? container.encode(base, forKey: .base)
        try? container.encode(eventId, forKey: .eventId)
    }
}

// periphery:ignore - DTO is meant to reflect the server
public struct EventFormDTO: Codable, Sendable {
    public init(id: EventFormID, primaryFeedField: String? = nil, secondaryFeedField: String? = nil, primaryField: String? = nil, variantField: String? = nil, name: String? = nil, description: String? = nil, userFields: [String]? = nil, archived: Bool? = nil, min: Int? = nil, max: Int? = nil, color: String? = nil, isDefault: Bool? = nil, fields: [EventFormFieldDTO]? = nil, style: StyleDTO? = nil) {
        self.id = id
        self.primaryFeedField = primaryFeedField
        self.secondaryFeedField = secondaryFeedField
        self.primaryField = primaryField
        self.variantField = variantField
        self.name = name
        self.description = description
        self.userFields = userFields
        self.archived = archived
        self.min = min
        self.max = max
        self.color = color
        self.isDefault = isDefault
        self.fields = fields
        self.style = style
    }
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case primaryFeedField
        case secondaryFeedField
        case primaryField
        case variantField
        case name
        case description
        case userFields
        case archived
        case id
        case min
        case max
        case color
        case isDefault = "default"
        case fields
        case style
    }
    public let id: EventFormID
    public let primaryFeedField: String?
    public let secondaryFeedField: String?
    public let primaryField: String?
    public let variantField: String?
    public let name: String?
    public let description: String?
    public let userFields: [String]?
    public let archived: Bool?
    public let min: Int?
    public let max: Int?
    
    public let color: String?
    public let isDefault: Bool?
    public let fields: [EventFormFieldDTO]?
    public let style: StyleDTO?
}

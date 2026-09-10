import Foundation

// periphery:ignore - DTO is meant to reflect the server
public struct EventDTO: Codable, Sendable {
    public init(id: EventID, name: String, maxObservationForms: Int? = nil, minObservationForms: Int? = nil, description: String? = nil, acl: [String : ACLDTO]? = nil, forms: [EventFormDTO]? = nil, teams: [TeamDTO]? = nil, layers: [MapLayerDTO]? = nil, style: StyleDTO? = nil) {
        self.id = id
        self.name = name
        self.maxObservationForms = maxObservationForms
        self.minObservationForms = minObservationForms
        self.description = description
        self.acl = acl
        self.forms = forms
        self.teams = teams
        self.layers = layers
        self.style = style
    }
    
    public let id: EventID
    public let name: String
    public let maxObservationForms: Int?
    public let minObservationForms: Int?
    public let description: String?
    
    public let acl: [String: ACLDTO]?
    public let forms: [EventFormDTO]?
    public let teams: [TeamDTO]?
    public let layers: [MapLayerDTO]?
    public let style: StyleDTO?
}

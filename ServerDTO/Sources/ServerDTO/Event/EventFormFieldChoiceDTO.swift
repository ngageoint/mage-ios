// periphery:ignore - DTO is meant to reflect the server
public struct EventFormFieldChoiceDTO: Codable, Sendable {
    public let id: Int
    public let title: String?
    public let value: Int
}

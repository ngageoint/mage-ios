import Foundation

// periphery:ignore - DTO is meant to reflect the server
public struct TeamDTO: Codable, Sendable {
    public let name: String?
    public let description: String?
    public let teamEventId: Int?
    public let id: String
    public let userIds: [String]?
    public let acl: [String: ACLDTO]?
}

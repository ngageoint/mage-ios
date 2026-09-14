// periphery:ignore - DTO is meant to reflect the server
public struct ACLDTO: Codable, Sendable {
    public init(role: String? = nil, permissions: [String]? = nil, userId: String? = nil) {
        self.role = role
        self.permissions = permissions
        self.userId = userId
    }
    
    public let role: String?
    public let permissions: [String]?
    public let userId: String?
}

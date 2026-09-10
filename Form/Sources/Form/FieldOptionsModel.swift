public struct FieldOptionsModel: Hashable, Codable, Sendable {
    public init(value: Int, id: Int, title: String) {
        self.value = value
        self.id = id
        self.title = title
    }
    
    public var value: Int
    public var id: Int
    public var title: String
}

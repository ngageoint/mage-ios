public enum TeamKey : String {
    case id
    case name
    case description
    case userIds
    case remoteId
    
    public var key: String {
        return self.rawValue
    }
}

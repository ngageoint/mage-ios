public enum EventKey : String {
    
    case id
    case forms
    case name
    case description
    case formId
    case remoteId
    case teams
    case maxObservationForms
    case minObservationForms
    case acl
    case layers
    
    public var key: String {
        return self.rawValue
    }
}

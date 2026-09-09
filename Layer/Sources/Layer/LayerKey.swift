public enum LayerKey: String {
    case id
    case name
    case type
    case url
    case formId
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
    
    public var key : String {
        return self.rawValue
    }
}

public enum StaticLayerKey: String {
    
    case properties
    case style
    case iconStyle
    case icon
    case href
    case id
    case localPath
    
    public var key: String {
        return self.rawValue
    }
}

public enum WMSLayerOptionsKey: String {
    case layers
    case format
    case styles
    case transparent
    case version
    
    public var key : String {
        return self.rawValue;
    }
}

public enum LayerType : String {
    case Feature
    case GeoPackage
    case Imagery
    
    public var key : String {
        return self.rawValue;
    }
}

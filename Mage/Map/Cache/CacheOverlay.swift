//
//  CacheOverlay.m
//  MAGE
//
//  Created by Brian Osborn on 12/17/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

@objc enum CacheOverlayType: Int {
    case XYZ_DIRECTORY
    case GEOPACKAGE
    case GEOPACKAGE_TILE_TABLE
    case GEOPACKAGE_FEATURE_TABLE
};

@objc class CacheOverlay: NSObject {
    var enabled: Bool = false
    var expanded: Bool = false
    var added: Bool = false
    var replaced: CacheOverlay?
    var name: String
    var cacheName: String
    var type: CacheOverlayType
    var iconImageName: String?
    var supportsChildren: Bool = false
    var isChild: Bool = false
    
    init(name: String, cacheName: String? = nil, type: CacheOverlayType, supportsChildren: Bool) {
        self.name = name
        self.cacheName = cacheName ?? name
        self.type = type
        self.supportsChildren = supportsChildren
        self.enabled = false
        self.expanded = false
    }
    
    func getChildren() -> [CacheOverlay] {
        []
    }
    
    func getParent() -> CacheOverlay? {
        nil
    }
    
    func getInfo() -> String? {
        nil
    }
    
    func removeFromMap(mapView: MKMapView) {
        
    }
    
    func onMapClick(locationCoordinates: CLLocationCoordinate2D, mapView: MKMapView) -> String? {
        nil
    }
    
    static func buildChildCacheName(name: String, childName: String) -> String {
        "\(name)-\(childName)"
    }
}

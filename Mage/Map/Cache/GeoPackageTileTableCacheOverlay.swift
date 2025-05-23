//
//  GeoPackageTileTableCacheOverlay.m
//  MAGE
//
//  Created by Brian Osborn on 12/18/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

import GeoPackage

class GeoPackageTileTableCacheOverlay: GeoPackageTableCacheOverlay {
    public var featureOverlayQueries: [GPKGFeatureOverlayQuery] = []
    
    public init(name: String, geoPackage: String, cacheName: String, count: Int, minZoom: Int, maxZoom: Int) {
        super.init(
            name: name,
            geoPackage: geoPackage,
            cacheName: cacheName,
            type: CacheOverlayType.GEOPACKAGE_TILE_TABLE,
            count: count,
            minZoom: minZoom,
            maxZoom: maxZoom
        )
        iconImageName = "layers"
    }
    
    override func getInfo() -> String {
        return "\(count) tile\(count == 1 ? "" : "s"), zoom: \(minZoom) - \(maxZoom)"
    }
    
    func onMapClick(coordinate: CLLocationCoordinate2D, mapView: MKMapView) -> String {
        var message = ""
        for featureOverlayQuery in featureOverlayQueries {
            if let overlayMessage = featureOverlayQuery.buildMapClickMessage(with: coordinate, andMapView: mapView) {
                if message.isEmpty {
                    message.append("\n\n")
                }
                message.append(overlayMessage)
            }
        }
        return message
    }
}

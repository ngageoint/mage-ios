//
//  XYZDirectoryCacheOverlay.m
//  MAGE
//
//  Created by Brian Osborn on 12/18/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

class XYZDirectoryCacheOverlay: CacheOverlay {
    var tileOverlay: MKTileOverlay?
    var minZoom: Int
    var maxZoom: Int
    var tileCount: Int
    var directory: String?
    
    init(name: String, directory: String) {
        self.directory = directory
        tileCount = 0
        minZoom = 100
        maxZoom = -1
        super.init(name: name, type: CacheOverlayType.XYZ_DIRECTORY, supportsChildren: false)
        self.iconImageName = "layers"
        
        let zooms = try? FileManager.default.contentsOfDirectory(atPath: directory)
        for zoom in zooms ?? [] {
            minZoom = min(minZoom, Int(zoom) ?? 100)
            maxZoom = max(maxZoom, Int(zoom) ?? -1)
            let zoomPath = (directory as NSString).appendingPathComponent(zoom)
            let xDirectories = try? FileManager.default.contentsOfDirectory(atPath: zoomPath)
            for xDirectory in xDirectories ?? [] {
                let xPath = (zoomPath as NSString).appendingPathComponent(xDirectory)
                let yDirectories = try? FileManager.default.contentsOfDirectory(atPath: xPath)
                for yDirectory in yDirectories ?? [] {
                    let yPath = (xPath as NSString).appendingPathComponent(yDirectory)
                    tileCount += (try? FileManager.default.contentsOfDirectory(atPath: yPath).count) ?? 0
                }
            }
        }
    }
    
    override func removeFromMap(mapView: MKMapView) {
        if let tileOverlay = tileOverlay {
            mapView.removeOverlay(tileOverlay)
            self.tileOverlay = nil
        }
    }
    
    override func getInfo() -> String? {
        "\(self.tileCount) tiles, zoom: \(self.minZoom) - \(self.maxZoom)"
    }
}

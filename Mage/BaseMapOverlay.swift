//
//  BaseMapOverlay.m
//  MAGE
//
//  Created by Daniel Barela on 1/8/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import MapFramework
import geopackage_ios

@objc class BaseMapOverlay: GPKGFeatureOverlay, OverlayRenderable {
    var renderer: MKOverlayRenderer {
        get {
            return MKTileOverlayRenderer(overlay: self)
        }
    }
    @objc public var darkTheme = false
    
    @objc public func cleanup() {
        super.close()
        featureTiles = nil
    }
    
    override init!(featureTiles: GPKGFeatureTiles!) {
        super.init(featureTiles: featureTiles)
    }
    
    override func retrieveTileWith(x: Int, andY y: Int, andZoom zoom: Int) -> Data! {
        let tileWidth = self.tileSize.width
        let tileHeight = self.tileSize.height
        
        UIGraphicsBeginImageContext(CGSize(width: tileWidth, height: tileHeight))
        let context = UIGraphicsGetCurrentContext()
        
        // Create the tile path
        let tilePath = CGMutablePath()
        tilePath.move(to: CGPoint(x: 0, y: 0))
        tilePath.addLine(to: CGPoint(x: 0, y: tileHeight))
        tilePath.addLine(to: CGPoint(x: tileWidth, y: tileHeight))
        tilePath.addLine(to: CGPoint(x: tileWidth, y: 0))
        tilePath.addLine(to: CGPoint(x: 0, y: 0))
        tilePath.closeSubpath()
        
        if darkTheme {
            context?.setFillColor(UIColor(hex: "#354566")!.cgColor)
        } else {
            context?.setFillColor(UIColor(hex: "#a4dded")!.cgColor)
        }
        
        context?.addPath(tilePath)
        context?.drawPath(using: .fill)
        
        let featureImage = self.featureTiles.drawTileWith(x: Int32(x), andY: Int32(y), andZoom: Int32(zoom))
        featureImage?.draw(in: CGRect(x: 0, y: 0, width: tileWidth, height: tileHeight))
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return GPKGImageConverter.toData(image, andFormat: GPKGCompressFormats.fromName(GPKG_CF_PNG_NAME))
    }
}

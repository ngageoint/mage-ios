//
//  BaseMapOverlay.m
//  MAGE
//
//  Created by Daniel Barela on 1/8/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

import Foundation
import geopackage_ios

@objc class BaseMapOverlay: GPKGFeatureOverlay, MageOverlay {
    var renderer: MKOverlayRenderer?
    @objc public var darkTheme = false
    
    override init!(featureTiles: GPKGFeatureTiles!) {
        super.init(featureTiles: featureTiles)
        renderer = MKTileOverlayRenderer(overlay: self)
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

//#import "BaseMapOverlay.h"
//#import <GPKGImageConverter.h>
//#import <HexColors.h>
//
//@implementation BaseMapOverlay
//
//-(NSData *) retrieveTileWithX: (NSInteger) x andY: (NSInteger) y andZoom: (NSInteger) zoom {
//    NSInteger tileWidth = self.tileSize.width;
//    NSInteger tileHeight = self.tileSize.height;
//    UIGraphicsBeginImageContext(CGSizeMake(tileWidth, tileHeight));
//    CGContextRef context = UIGraphicsGetCurrentContext();
//
//    // Create the tile path
//    CGMutablePathRef tilePath = CGPathCreateMutable();
//    CGPathMoveToPoint(tilePath, NULL, 0, 0);
//    CGPathAddLineToPoint(tilePath, NULL, 0, tileHeight);
//    CGPathAddLineToPoint(tilePath, NULL, tileWidth, tileHeight);
//    CGPathAddLineToPoint(tilePath, NULL, tileWidth, 0);
//    CGPathAddLineToPoint(tilePath, NULL, 0, 0);
//    CGPathCloseSubpath(tilePath);
//    if (self.darkTheme) {
//        CGContextSetFillColorWithColor(context, [UIColor hx_colorWithHexRGBAString:@"#354566"].CGColor);
//    } else {
//        CGContextSetFillColorWithColor(context, [UIColor hx_colorWithHexRGBAString:@"#a4dded"].CGColor);
//    }
//    CGContextAddPath(context, tilePath);
//    CGPathDrawingMode tileMode = kCGPathFill;
//    CGContextDrawPath(context, tileMode);
//    CGPathRelease(tilePath);
//
//    UIImage *featureImage = [self.featureTiles drawTileWithX:(int)x andY:(int)y andZoom:(int)zoom];
//    [featureImage drawInRect:CGRectMake(0, 0, tileWidth, tileHeight)];
//
//    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//
//    return [GPKGImageConverter toData:image andFormat:[GPKGCompressFormats fromName:GPKG_CF_PNG_NAME]];
//}
//
//
//@end

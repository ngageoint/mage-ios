//
//  BaseMapOverlay.m
//  MAGE
//
//  Created by Daniel Barela on 1/8/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import "BaseMapOverlay.h"
#import <GPKGImageConverter.h>
#import <HexColor.h>

@implementation BaseMapOverlay

-(NSData *) retrieveTileWithX: (NSInteger) x andY: (NSInteger) y andZoom: (NSInteger) zoom {
    NSInteger tileWidth = self.tileSize.width;
    NSInteger tileHeight = self.tileSize.height;
    UIGraphicsBeginImageContext(CGSizeMake(tileWidth, tileHeight));
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Create the tile path
    CGMutablePathRef tilePath = CGPathCreateMutable();
    CGPathMoveToPoint(tilePath, NULL, 0, 0);
    CGPathAddLineToPoint(tilePath, NULL, 0, tileHeight);
    CGPathAddLineToPoint(tilePath, NULL, tileWidth, tileHeight);
    CGPathAddLineToPoint(tilePath, NULL, tileWidth, 0);
    CGPathAddLineToPoint(tilePath, NULL, 0, 0);
    CGPathCloseSubpath(tilePath);
    if (self.darkTheme) {
        CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:@"#354566"].CGColor);
    } else {
        CGContextSetFillColorWithColor(context, [UIColor colorWithHexString:@"#a4dded"].CGColor);
    }
    CGContextAddPath(context, tilePath);
    CGPathDrawingMode tileMode = kCGPathFill;
    CGContextDrawPath(context, tileMode);
    CGPathRelease(tilePath);
    
    UIImage *featureImage = [self.featureTiles drawTileWithX:(int)x andY:(int)y andZoom:(int)zoom];
    [featureImage drawInRect:CGRectMake(0, 0, tileWidth, tileHeight)];

    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [GPKGImageConverter toData:image andFormat:[GPKGCompressFormats fromName:GPKG_CF_PNG_NAME]];
}


@end

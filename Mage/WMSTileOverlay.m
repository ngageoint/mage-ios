//
//  WMSTileOverlay.m
//  MAGE
//
//  Created by Dan Barela on 8/6/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "WMSTileOverlay.h"

@interface WMSTileOverlay ()
@property (nonatomic, strong) NSString *url;
@end

@implementation WMSTileOverlay 


/**
 Initializes a WMSTileOverlay
 
 url should look something like this:
 
 https://yourWmsService.com/wms?request=GetMap&service=WMS&styles=default&layers=layer&version=1.3.0&CRS=EPSG:4326&width=256&height=256&format=image/png
 
 - parameter url: A string representation of URL to WMS Service
 - returns: An overlay to be used with MapKit
 */
- (id) initWithURLTemplate:(NSString *)url {
    self.url = url;
    return [super initWithURLTemplate:url];
}

- (double) xOfColumn:(long) column andZoom: (long) zoom {
    double x = (double) column;
    double z = (double) zoom;
    
    return x / pow(2.0, z) * 360.0 - 180;
}

- (double) yOfRow:(long) row andZoom: (long) zoom {
    double y = (double) row;
    double z = (double) zoom;
    double n = M_PI - 2.0 * M_PI * y / pow(2.0, z);
    return 180.0 / M_PI * atan(0.5 * (exp(n) - exp (-n)));
}

- (double) mercatorXOfLongitude: (double) lon {
    return lon * 20037508.34 / 180;
}

- (double) mercatorYOfLatitude: (double) lat {
    double y = log(tan((90 + lat) * M_PI / 360)) / (M_PI / 180);
    y = y * 20037508.34 / 180;
    return y;
}

- (long) tileZ: (MKZoomScale) zoomScale {
    double numTilesAt1_0 = MKMapSizeWorld.width / 256.0;
    double zoomLevelAt1_0 = log2(numTilesAt1_0);
    double zoomLevel = MAX(0, zoomLevelAt1_0 + floor(log2f((float)zoomScale)) + 0.5);
    return (long) zoomLevel;
}

- (NSURL *) URLForTilePath:(MKTileOverlayPath) path {
    double left = [self mercatorXOfLongitude: [self xOfColumn:path.x andZoom:path.z]];
    double right = [self mercatorXOfLongitude: [self xOfColumn:path.x+1 andZoom:path.z]];
    double bottom = [self mercatorYOfLatitude: [self yOfRow: path.y+1 andZoom:path.z]];
    double top = [self mercatorYOfLatitude: [self yOfRow:path.y andZoom:path.z]];
    return [NSURL URLWithString:[NSString stringWithFormat:@"%@&BBOX=%f,%f,%f,%f", self.url, left, bottom, right, top]];
}

- (void)loadTileAtPath:(MKTileOverlayPath)path result:(void (^)(NSData * _Nullable, NSError * _Nullable))result {
    NSURL *url1 = [self URLForTilePath:path];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url1];
    request.HTTPMethod = @"GET";
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        result(data, error);
    }] resume];
}

@end

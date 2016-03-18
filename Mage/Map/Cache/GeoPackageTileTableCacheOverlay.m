//
//  GeoPackageTileTableCacheOverlay.m
//  MAGE
//
//  Created by Brian Osborn on 12/18/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "GeoPackageTileTableCacheOverlay.h"

@implementation GeoPackageTileTableCacheOverlay

-(instancetype) initWithName: (NSString *) name andGeoPackage: (NSString *) geoPackage andCacheName: (NSString *) cacheName andCount: (int) count andMinZoom: (int) minZoom andMaxZoom: (int) maxZoom{
    self = [super initWithName:name andGeoPackage:geoPackage andCacheName:cacheName andType:GEOPACKAGE_TILE_TABLE andCount:count andMinZoom:minZoom andMaxZoom:maxZoom];
    if(self){
        self.featureOverlayQueries = [[NSMutableArray alloc] init];
    }
    return self;
}

-(NSString *) getIconImageName{
    return @"layers";
}

-(NSString *) getInfo{
    return [NSString stringWithFormat:@"tiles: %d, zoom: %d - %d", [self getCount], [self getMinZoom], [self getMaxZoom]];
}

-(NSString *) onMapClickWithLocationCoordinate: (CLLocationCoordinate2D) locationCoordinate andMap: (MKMapView *) mapView{
    NSMutableString * message = nil;
    
    if(self.featureOverlayQueries != nil){
        for(GPKGFeatureOverlayQuery * featureOverlayQuery in self.featureOverlayQueries){
            NSString * overlayMessage = [featureOverlayQuery buildMapClickMessageWithLocationCoordinate:locationCoordinate andMapView:mapView];
            if(overlayMessage != nil){
                if(message == nil){
                    message = [[NSMutableString alloc] init];
                }else{
                    [message appendString:@"\n\n"];
                }
                [message appendString:overlayMessage];
            }
        }
    }
    
    return message;
}

@end

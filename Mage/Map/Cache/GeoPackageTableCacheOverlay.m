//
//  GeoPackageTableCacheOverlay.m
//  MAGE
//
//  Created by Brian Osborn on 12/18/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "GeoPackageTableCacheOverlay.h"

@interface GeoPackageTableCacheOverlay ()

@property (strong, nonatomic) NSString * geoPackage;
@property (nonatomic) int count;
@property (nonatomic) int minZoom;
@property (nonatomic) int maxZoom;

@end

@implementation GeoPackageTableCacheOverlay

-(instancetype) initWithName: (NSString *) name andGeoPackage: (NSString *) geoPackage andCacheName: (NSString *) cacheName andType: (enum CacheOverlayType) type andCount: (int) count andMinZoom: (int) minZoom andMaxZoom: (int) maxZoom{
    self = [super initWithName:name andCacheName:cacheName andType:type andSupportsChildren:false];
    if(self){
        self.geoPackage = geoPackage;
        self.count = count;
        self.minZoom = minZoom;
        self.maxZoom = maxZoom;
    }
    return self;
}

-(void) removeFromMap: (MKMapView *) mapView{
    if(self.tileOverlay != nil){
        [mapView removeOverlay:self.tileOverlay];
        self.tileOverlay = nil;
    }
}

-(NSString *) getGeoPackage{
    return self.geoPackage;
}

-(int) getCount{
    return self.count;
}

-(int) getMinZoom{
    return self.minZoom;
}

-(int) getMaxZoom{
    return self.maxZoom;
}

@end

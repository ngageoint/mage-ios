//
//  GeoPackageFeatureTableCacheOverlay.m
//  MAGE
//
//  Created by Brian Osborn on 12/18/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "GeoPackageFeatureTableCacheOverlay.h"
#import "GPKGMapShape.h"

NSInteger const GEO_PACKAGE_FEATURE_TABLE_MAX_ZOOM = 21;

@interface GeoPackageFeatureTableCacheOverlay ()

@property (nonatomic) BOOL indexed;
@property (nonatomic) enum WKBGeometryType geometryType;
//@property (strong, nonatomic) NSMutableDictionary<NSNumber *, GPKGMapShape *> * shapes;

@end

@implementation GeoPackageFeatureTableCacheOverlay

-(instancetype) initWithName: (NSString *) name andGeoPackage: (NSString *) geoPackage andCacheName: (NSString *) cacheName andCount: (int) count andMinZoom: (int) minZoom andIndexed: (BOOL) indexed andGeometryType: (enum WKBGeometryType) geometryType{
    self = [super initWithName:name andGeoPackage:geoPackage andCacheName:cacheName andType:GEOPACKAGE_FEATURE_TABLE andCount:count andMinZoom:minZoom andMaxZoom:GEO_PACKAGE_FEATURE_TABLE_MAX_ZOOM];
    if(self){
        //self.shapes = [[NSMutableDictionary alloc] init];
        self.indexed = indexed;
        self.geometryType = geometryType;
    }
    return self;
}

-(NSString *) getInfo{
    return [NSString stringWithFormat:@"features: %d, zoom: %d - %d", [self getCount], [self getMinZoom], [self getMaxZoom]];
}

-(BOOL) getIndexed{
    return self.indexed;
}

-(enum WKBGeometryType) getGeometryType{
    return self.geometryType;
}

@end

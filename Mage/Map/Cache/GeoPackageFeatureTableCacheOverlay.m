//
//  GeoPackageFeatureTableCacheOverlay.m
//  MAGE
//
//  Created by Brian Osborn on 12/18/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "GeoPackageFeatureTableCacheOverlay.h"
#import "GPKGMapShapeConverter.h"

NSInteger const GEO_PACKAGE_FEATURE_TABLE_MAX_ZOOM = 21;

@interface GeoPackageFeatureTableCacheOverlay ()

@property (nonatomic) BOOL indexed;
@property (nonatomic) enum WKBGeometryType geometryType;
@property (strong, nonatomic) NSMutableDictionary<NSNumber *, GPKGMapShape *> * shapes;

@end

@implementation GeoPackageFeatureTableCacheOverlay

-(instancetype) initWithName: (NSString *) name andGeoPackage: (NSString *) geoPackage andCacheName: (NSString *) cacheName andCount: (int) count andMinZoom: (int) minZoom andIndexed: (BOOL) indexed andGeometryType: (enum WKBGeometryType) geometryType{
    self = [super initWithName:name andGeoPackage:geoPackage andCacheName:cacheName andType:GEOPACKAGE_FEATURE_TABLE andCount:count andMinZoom:minZoom andMaxZoom:GEO_PACKAGE_FEATURE_TABLE_MAX_ZOOM];
    if(self){
        self.shapes = [[NSMutableDictionary alloc] init];
        self.indexed = indexed;
        self.geometryType = geometryType;
    }
    return self;
}

-(void) removeFromMap: (MKMapView *) mapView{
    for(GPKGMapShape * shape in [self.shapes allValues]){
        [shape removeFromMapView: mapView];
    }
    [self.shapes removeAllObjects];
    [super removeFromMap: mapView];
}

-(NSString *) getInfo{
    return [NSString stringWithFormat:@"features: %d, zoom: %d - %d", [self getCount], [self getMinZoom], [self getMaxZoom]];
}

-(NSString *) onMapClickWithLocationCoordinate: (CLLocationCoordinate2D) locationCoordinate andMap: (MKMapView *) mapView{
    NSString * message = nil;
    
    if(self.featureOverlayQuery != nil){
        message = [self.featureOverlayQuery buildMapClickMessageWithLocationCoordinate:locationCoordinate andMapView:mapView];
    }
    
    return message;
}

-(BOOL) getIndexed{
    return self.indexed;
}

-(enum WKBGeometryType) getGeometryType{
    return self.geometryType;
}

-(void) addShapeWithId: (NSNumber *) id andShape: (GPKGMapShape *) shape{
    [self.shapes setObject:shape forKey:id];
}

-(GPKGMapShape *) removeShapeWithId: (NSNumber *) id{
    GPKGMapShape * shape = [self.shapes objectForKey:id];
    if(shape != nil){
        [self.shapes removeObjectForKey:id];
    }
    return shape;
}

-(GPKGMapShape *) addShapeWithId: (NSNumber *) id andShape: (GPKGMapShape *) shape toMapView: (MKMapView *) mapView{
    GPKGMapShape * mapShape = [GPKGMapShapeConverter addMapShape:shape toMapView:mapView];
    [self addShapeWithId:id andShape:shape];
    return mapShape;
}

-(GPKGMapShape *) removeShapeFromMapWithId: (NSNumber *) id fromMapView: (MKMapView *) mapView{
    GPKGMapShape * shape = [self removeShapeWithId: id];
    if(shape != nil){
        [shape removeFromMapView:mapView];
    }
    return shape;
}

@end

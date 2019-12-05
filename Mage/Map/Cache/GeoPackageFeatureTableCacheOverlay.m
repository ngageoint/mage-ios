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
@property (nonatomic) enum SFGeometryType geometryType;
@property (strong, nonatomic) NSMutableDictionary<NSNumber *, GPKGMapShape *> * shapes;
@property (strong, nonatomic) NSMutableArray<GeoPackageTileTableCacheOverlay *> * linkedTiles;

@end

@implementation GeoPackageFeatureTableCacheOverlay

-(instancetype) initWithName: (NSString *) name andGeoPackage: (NSString *) geoPackage andCacheName: (NSString *) cacheName andCount: (int) count andMinZoom: (int) minZoom andIndexed: (BOOL) indexed andGeometryType: (enum SFGeometryType) geometryType{
    self = [super initWithName:name andGeoPackage:geoPackage andCacheName:cacheName andType:GEOPACKAGE_FEATURE_TABLE andCount:count andMinZoom:minZoom andMaxZoom:GEO_PACKAGE_FEATURE_TABLE_MAX_ZOOM];
    if(self){
        self.shapes = [[NSMutableDictionary alloc] init];
        self.indexed = indexed;
        self.geometryType = geometryType;
        self.linkedTiles = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void) removeFromMap: (MKMapView *) mapView{
    for(GPKGMapShape * shape in [self.shapes allValues]){
        [shape removeFromMapView: mapView];
    }
    [self.shapes removeAllObjects];
    [super removeFromMap: mapView];
    
    for(GeoPackageTileTableCacheOverlay * linkedTileTable in self.linkedTiles){
        [linkedTileTable removeFromMap:mapView];
    }
}

-(NSString *) getIconImageName{
    return @"marker_outline";
}

-(NSString *) getInfo{
    int minZoom = [self getMinZoom];
    int maxZoom = [self getMaxZoom];
    for(GeoPackageTileTableCacheOverlay * linkedTileTable in self.linkedTiles){
        minZoom = MIN(minZoom, [linkedTileTable getMinZoom]);
        maxZoom = MAX(maxZoom, [linkedTileTable getMaxZoom]);
    }
    return [NSString stringWithFormat:@"%d feature%@, zoom: %d - %d", [self getCount], [self getCount] == 1 ? @"" : @"s", minZoom, maxZoom];
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

-(enum SFGeometryType) getGeometryType{
    return self.geometryType;
}

-(void) addShapeWithId: (NSNumber *) id andShape: (GPKGMapShape *) shape{
    @try {
    [self.shapes setObject:shape forKey:id];
    }
    @catch (NSException *e) {
        NSLog(@"Failure adding shape to map %@", e);
    }
}

-(GPKGMapShape *) removeShapeWithId: (NSNumber *) id{
    GPKGMapShape * shape = [self.shapes objectForKey:id];
    if(shape != nil){
        [self.shapes removeObjectForKey:id];
    }
    return shape;
}

-(GPKGMapShape *) removeShapeFromMapWithId: (NSNumber *) id fromMapView: (MKMapView *) mapView{
    GPKGMapShape * shape = [self removeShapeWithId: id];
    if(shape != nil){
        [shape removeFromMapView:mapView];
    }
    return shape;
}

-(void) addLinkedTileTable: (GeoPackageTileTableCacheOverlay *) tileTable{
    [self.linkedTiles addObject:tileTable];
}

-(NSArray<GeoPackageTileTableCacheOverlay *> *) getLinkedTileTables{
    return self.linkedTiles;
}

@end

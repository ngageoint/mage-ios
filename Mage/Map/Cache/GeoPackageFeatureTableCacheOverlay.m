//
//  GeoPackageFeatureTableCacheOverlay.m
//  MAGE
//
//  Created by Brian Osborn on 12/18/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "GeoPackageFeatureTableCacheOverlay.h"
#import "GPKGMapShapeConverter.h"
#import "GPKGMapUtils.h"
#import "GPKGProperties.h"
#import "GPKGPropertyConstants.h"
#import "GPKGDataColumnsDao.h"
#import "GPKGGeoPackageFactory.h"

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

-(GPKGFeatureTableData *) getFeatureTableDataWithLocationCoordinate: (CLLocationCoordinate2D) locationCoordinate andMap: (MKMapView *) mapView{
    GPKGFeatureTableData * featureTableData = nil;
    if(self.featureOverlayQuery != nil){
        
        featureTableData = [self.featureOverlayQuery buildMapClickTableDataWithLocationCoordinate:locationCoordinate andMapView:mapView];
    }
    
    return featureTableData;
}

- (BOOL) verifyIndexAndShouldReturnInformationAtLocation: (CLLocationCoordinate2D) tapLocation andZoom: (double) zoom {
    @try {
        return [self.featureOverlayQuery isIndexed] 
            && (self.featureOverlayQuery.maxFeaturesInfo || self.featureOverlayQuery.featuresInfo)
            && [self.featureOverlayQuery onAtZoom:zoom andLocationCoordinate:tapLocation];
        
    } @catch (NSException *e) {
        NSLog(@"Verify index exception: %@", [e description]);
    }
    return FALSE;
}

- (NSArray<GeoPackageFeatureItem *> *) buildFeatureItems: (GPKGFeatureIndexResults *) results
                                       defaultCoordinate: (CLLocationCoordinate2D) defaultCoordinate
{
    NSMutableArray<GeoPackageFeatureItem *> *featureItems = [[NSMutableArray alloc] init];
    
    @try {
        
        GPKGGeoPackage *geoPackage = [[GPKGGeoPackageFactory manager] open:[self getGeoPackage]];
        for (GPKGFeatureRow *featureRow in results) {
            GeoPackageFeatureItem *featureItem = [[GeoPackageFeatureItem alloc] initWithFeatureRow:featureRow geoPackage:geoPackage layerName:[self getName] projection:self.featureOverlayQuery.featureTiles.featureDao.projection];
            if (featureItem != nil) {
                [featureItems addObject:featureItem];
            }
        }
    } @catch (NSException *e) {
        NSLog(@"Build Map Click Message Error: %@", [e description]);
    }
    return featureItems;
}

- (NSArray<GeoPackageFeatureKey *> *) buildFeatureKeys: (GPKGFeatureIndexResults *) results {
    NSMutableArray<GeoPackageFeatureKey *> *featureKeys = [[NSMutableArray alloc] init];
    
    @try {
        for (GPKGFeatureRow *featureRow in results) {
            int featureId = featureRow.idValue;
            NSString * tableName = featureRow.tableName;
            [featureKeys addObject: [[GeoPackageFeatureKey alloc] initWithGeoPackageName:[self getGeoPackage]
                                                                               featureId:featureId
                                                                               layerName:[self getName]
                                                                               tableName:tableName
                                    ]
            ];
        }
    } @catch (NSException *e) {
        NSLog(@"Build Map Click Message Error: %@", [e description]);
    }
    return featureKeys;
}

- (NSArray<GeoPackageFeatureItem *> *) getFeaturesNearTap: (CLLocationCoordinate2D) tapLocation andMap: (MKMapView *) mapView {
    NSMutableArray<GeoPackageFeatureItem *> *featureItems = [[NSMutableArray alloc] init];
    
    // Get the zoom level
    double zoom = [GPKGMapUtils currentZoomWithMapView:mapView];
    if (![self verifyIndexAndShouldReturnInformationAtLocation:tapLocation andZoom:zoom]) {
        return featureItems;
    }
    
    @try {
        // Get the number of features in the tile location
        int tileFeatureCount = [self.featureOverlayQuery tileFeatureCountWithLocationCoordinate:tapLocation andDoubleZoom:zoom];
        
        // If more than a configured max features to drawere
        if([self.featureOverlayQuery moreThanMaxFeatures:tileFeatureCount]){
            
            // Build the max features message
            if(self.featureOverlayQuery.maxFeaturesInfo){
                GeoPackageFeatureItem *featureItem = [[GeoPackageFeatureItem alloc] initWithMaxFeaturesReached:true featureCount:tileFeatureCount layerName:[self getName]];
                [featureItems addObject:featureItem];
                return featureItems;
            }
        }
        
        
        GPKGFeatureIndexResults * results = [self getFeatureResultsNearTap:tapLocation andMap:mapView];
        [featureItems addObjectsFromArray: [self buildFeatureItems:results defaultCoordinate:tapLocation]];
    } @catch (NSException *e) {
        NSLog(@"Build Map Click Message Error: %@", [e description]);
    }
    
    return featureItems;
}

- (NSArray<GeoPackageFeatureKey *> *) getFeatureKeysNearTap: (CLLocationCoordinate2D) tapLocation andMap: (MKMapView *) mapView {
    NSMutableArray<GeoPackageFeatureKey *> *featureKeys = [[NSMutableArray alloc] init];
    
    // Get the zoom level
    double zoom = [GPKGMapUtils currentZoomWithMapView:mapView];
    if (![self verifyIndexAndShouldReturnInformationAtLocation:tapLocation andZoom:zoom]) {
        return featureKeys;
    }
    
    @try {
        // Get the number of features in the tile location
        int tileFeatureCount = [self.featureOverlayQuery tileFeatureCountWithLocationCoordinate:tapLocation andDoubleZoom:zoom];
        
        // If more than a configured max features to drawere
        if([self.featureOverlayQuery moreThanMaxFeatures:tileFeatureCount]){
            
            // Build the max features message
            if(self.featureOverlayQuery.maxFeaturesInfo){
                GeoPackageFeatureKey *featureKey = [[GeoPackageFeatureKey alloc] initWithGeoPackageName:[self getGeoPackage] featureCount:tileFeatureCount layerName:[self getName] tableName: [self getName]];
                [featureKeys addObject:featureKey];
                return featureKeys;
            }
        }
        
        GPKGFeatureIndexResults * results = [self getFeatureResultsNearTap:tapLocation andMap:mapView];
        [featureKeys addObjectsFromArray: [self buildFeatureKeys:results]];
    } @catch (NSException *e) {
        NSLog(@"Build Map Click Message Error: %@", [e description]);
    }
    
    return featureKeys;
}

// all checks to ensure we should query should have already been before this method is called
- (nullable GPKGFeatureIndexResults *) getFeatureResultsNearTap: (CLLocationCoordinate2D) tapLocation andMap: (MKMapView *) mapView {
    NSMutableArray<GeoPackageFeatureItem *> *featureItems = [[NSMutableArray alloc] init];
    // Get the zoom level
    double zoom = [GPKGMapUtils currentZoomWithMapView:mapView];
    
    // Build a bounding box to represent the click location
    GPKGBoundingBox * boundingBox = [GPKGMapUtils buildClickBoundingBoxWithLocationCoordinate:tapLocation andMapView:mapView andScreenPercentage:self.featureOverlayQuery.screenClickPercentage];
    
    
    @try {
        // Get the number of features in the tile location
        int tileFeatureCount = [self.featureOverlayQuery tileFeatureCountWithLocationCoordinate:tapLocation andDoubleZoom:zoom];
        
        // If more than a configured max features to drawere
        if([self.featureOverlayQuery moreThanMaxFeatures:tileFeatureCount]){
            
            // Build the max features message
            if(self.featureOverlayQuery.maxFeaturesInfo){
                GeoPackageFeatureItem *featureItem = [[GeoPackageFeatureItem alloc] initWithMaxFeaturesReached:true featureCount:tileFeatureCount layerName:[self getName]];
                [featureItems addObject:featureItem];
            }
        }
        // Else, query for the features near the click
        else if(self.featureOverlayQuery.featuresInfo){
            // Query for results and build the message
            return [self.featureOverlayQuery queryFeaturesWithBoundingBox:boundingBox inProjection:nil];
        }
    } @catch (NSException *e) {
        NSLog(@"Build Map Click Message Error: %@", [e description]);
    }
    return nil;
}

- (NSString *) attemptToCreateTitle: (NSDictionary *) values {
    __block NSString *title = @"GeoPackage Feature";
    [values.allKeys enumerateObjectsUsingBlock:^(id  _Nonnull key, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *keyStr = ((NSString*)key).lowercaseString;
        if ([keyStr isEqualToString:@"name"]) {
            title = [values objectForKey:(NSString*)key];
            *stop = true;
        }
        if ([keyStr isEqualToString:@"title"]) {
            title = [values objectForKey:(NSString*)key];
            *stop = true;
        }
    }];
    
    return title;
}

-(NSString *) columnNameWithDataColumnsDao: (GPKGDataColumnsDao *) dataColumnsDao andFeatureRow: (GPKGFeatureRow *) featureRow andColumnName: (NSString *) columnName{
    
    NSString * newColumnName = columnName;
    
    if(dataColumnsDao != nil){
        GPKGDataColumns * dataColumn = [dataColumnsDao dataColumnByTableName:featureRow.table.tableName andColumnName:columnName];
        if(dataColumn != nil){
            newColumnName = dataColumn.name;
        }
    }
    
    return newColumnName;
}

-(NSString *) columnNameWithDataColumnsDao: (GPKGDataColumnsDao *) dataColumnsDao andAttributesRow: (GPKGAttributesRow *) attributeRow andColumnName: (NSString *) columnName{
    
    NSString * newColumnName = columnName;
    
    if(dataColumnsDao != nil){
        GPKGDataColumns * dataColumn = [dataColumnsDao dataColumnByTableName:attributeRow.table.tableName andColumnName:columnName];
        if(dataColumn != nil){
            newColumnName = dataColumn.name;
        }
    }
    
    return newColumnName;
}

-(nullable GPKGDataColumnsDao *) dataColumnsDao: (GPKGConnection *) database {
    
    GPKGDataColumnsDao * dataColumnsDao = [[GPKGDataColumnsDao alloc] initWithDatabase:database];
    
    if(![dataColumnsDao tableExists]){
        dataColumnsDao = nil;
    }
    
    return dataColumnsDao;
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

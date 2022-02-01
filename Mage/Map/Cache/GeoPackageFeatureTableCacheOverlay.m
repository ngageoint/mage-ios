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

- (NSArray<GeoPackageFeatureItem *> *) getFeaturesNearTap: (CLLocationCoordinate2D) tapLocation andMap: (MKMapView *) mapView {
    NSMutableArray<GeoPackageFeatureItem *> *featureItems = [[NSMutableArray alloc] init];
    // Get the zoom level
    double zoom = [GPKGMapUtils currentZoomWithMapView:mapView];
    
    // Build a bounding box to represent the click location
    GPKGBoundingBox * boundingBox = [GPKGMapUtils buildClickBoundingBoxWithLocationCoordinate:tapLocation andMapView:mapView andScreenPercentage:self.featureOverlayQuery.screenClickPercentage];
    
    // Get the map click distance tolerance
    GPKGMapTolerance *tolerance = [GPKGMapUtils toleranceWithLocationCoordinate:tapLocation andMapView:mapView andScreenPercentage:self.featureOverlayQuery.screenClickPercentage];
    
    GPKGFeatureTableStyles *styles = self.featureOverlayQuery.featureTiles.featureTableStyles;
    
    // Verify the features are indexed and we are getting information
    if([self.featureOverlayQuery isIndexed] && (self.featureOverlayQuery.maxFeaturesInfo || self.featureOverlayQuery.featuresInfo)){
        
        @try {
            
            if([self.featureOverlayQuery onAtZoom:zoom andLocationCoordinate:tapLocation]){
                
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
                    GPKGGeoPackage *geoPackage = [[GPKGGeoPackageFactory manager] open:[self getGeoPackage]];
                    GPKGExtendedRelationsDao *relationsDao = [GPKGExtendedRelationsDao createWithDatabase:geoPackage.database];
                    GPKGRelatedTablesExtension *rte = [[GPKGRelatedTablesExtension alloc] initWithGeoPackage:geoPackage];
                    NSMutableArray<GPKGExtendedRelation *> *mediaTables = [[NSMutableArray alloc] init];
                    NSMutableArray<GPKGExtendedRelation *> *attributeTables = [[NSMutableArray alloc] init];
                    
                    if ([relationsDao tableExists]){
                        GPKGResultSet *relations = [relationsDao relationsToBaseTable:[self getName]];
                        @try {
                            while([relations moveToNext]){
                                GPKGExtendedRelation *extendedRelation = [relationsDao relation:relations];
                                if ([extendedRelation relationType] == [GPKGRelationTypes fromName:GPKG_RT_MEDIA_NAME]){
                                    [mediaTables addObject:extendedRelation];
                                } else if ([extendedRelation relationType] == [GPKGRelationTypes fromName:GPKG_RT_ATTRIBUTES_NAME]) {
                                    [attributeTables addObject:extendedRelation];
                                } else if ([extendedRelation relationType] == [GPKGRelationTypes fromName:GPKG_RT_SIMPLE_ATTRIBUTES_NAME]) {
                                    [attributeTables addObject:extendedRelation];
                                }
                            }
                        } @finally {
                            [relations close];
                        }
                    }
                    
                    // Query for results and build the message
                    GPKGFeatureIndexResults * results = [self.featureOverlayQuery queryFeaturesWithBoundingBox:boundingBox inProjection:nil];
                
                    for (GPKGFeatureRow *featureRow in results) {
                        NSMutableArray<GPKGMediaRow *> * medias = [[NSMutableArray alloc] init];
                        NSMutableArray<GPKGAttributesRow *> *attributes = [NSMutableArray array];
                        
                        int featureId = featureRow.idValue;
                        for (GPKGExtendedRelation *relation in mediaTables) {
                            NSArray<NSNumber *> *relatedMedia = [rte mappingsForTableName:relation.mappingTableName withBaseId:featureId];
                            GPKGMediaDao *mediaDao = [rte mediaDaoForTableName:relation.relatedTableName];
                            [medias addObjectsFromArray: [mediaDao rowsWithIds:relatedMedia]];
                        }
                        
                        for (GPKGExtendedRelation *relation in attributeTables) {
                            NSArray<NSNumber *> *relatedAttributes = [rte mappingsForTableName:relation.mappingTableName withBaseId:featureId];
                            
                            GPKGAttributesDao *attributesDao = [geoPackage attributesDaoWithTableName:relation.relatedTableName];
                            
                            for(NSNumber *relatedAttribute in relatedAttributes){
                                GPKGAttributesRow *row = (GPKGAttributesRow *)[attributesDao queryForIdObject:relatedAttribute];
                                if(row != nil){
                                    [attributes addObject:row];
                                }
                            }
                        }
                        
                        GPKGDataColumnsDao *dataColumnsDao = [self dataColumnsDao:self.featureOverlayQuery.featureTiles.featureDao.database];
                        
                        NSMutableDictionary * values = [NSMutableDictionary dictionary];
                        NSMutableDictionary *featureDataTypes = [NSMutableDictionary dictionary];
                        NSString * geometryColumnName = nil;
                        
                        CLLocationCoordinate2D coordinate = tapLocation;
                        
                        int geometryColumn = [featureRow geometryColumnIndex];
                        for(int i = 0; i < [featureRow columnCount]; i++){
                            
                            NSObject * value = [featureRow valueWithIndex:i];
                            
                            NSString * columnName = [featureRow columnNameWithIndex:i];
                            
                            columnName = [self columnNameWithDataColumnsDao:dataColumnsDao andFeatureRow:featureRow andColumnName:columnName];
                            
                            if(i == geometryColumn){
                                geometryColumnName = columnName;
                                GPKGGeometryData *geometry = (GPKGGeometryData *)value;
                                SFPoint *centroid = [geometry.geometry centroid];
                                SFPProjectionTransform *transform = [[SFPProjectionTransform alloc] initWithFromProjection:self.featureOverlayQuery.featureTiles.featureDao.projection andToEpsg:4326];
                                centroid = [transform transformWithPoint:centroid];
                                coordinate = CLLocationCoordinate2DMake([centroid.y doubleValue], [centroid.x doubleValue]);
                            }
                            [featureDataTypes setValue:[GPKGDataTypes name:featureRow.featureColumns.columns[i].dataType] forKey:columnName];
                            if(value != nil){
                                [values setObject:value forKey:columnName];
                            }
                        }
                        
                        GPKGFeatureRowData * featureRowData = [[GPKGFeatureRowData alloc] initWithValues:values andGeometryColumnName:geometryColumnName];
                        
                        NSMutableArray<GeoPackageFeatureItem *> *attributeFeatureRowData = [NSMutableArray array];
                        
                        for (GPKGAttributesRow *row in attributes) {
                            NSMutableArray<GPKGExtendedRelation *> *attributeMediaTables = [[NSMutableArray alloc] init];
                            NSArray<GPKGMediaRow *> * attributeMedias = nil;


                            if ([relationsDao tableExists]){
                                GPKGResultSet *relations = [relationsDao relationsToBaseTable: row.attributesTable.tableName ];
                                @try {
                                    while([relations moveToNext]){
                                        GPKGExtendedRelation *extendedRelation = [relationsDao relation:relations];
                                        if ([extendedRelation relationType] == [GPKGRelationTypes fromName:GPKG_RT_MEDIA_NAME]){
                                            [attributeMediaTables addObject:extendedRelation];
                                        }
                                    }
                                } @finally {
                                    [relations close];
                                }
                            }
                            
                            int attributeId = row.idValue;
                            for (GPKGExtendedRelation *relation in attributeMediaTables) {
                                NSArray<NSNumber *> *relatedMedia = [rte mappingsForTableName:relation.mappingTableName withBaseId:attributeId];
                                GPKGMediaDao *mediaDao = [rte mediaDaoForTableName:relation.relatedTableName];
                                attributeMedias = [mediaDao rowsWithIds:relatedMedia];
                            }
                            NSMutableDictionary * values = [NSMutableDictionary dictionary];
                            NSMutableDictionary *attributeDataTypes = [NSMutableDictionary dictionary];
                            NSString * geometryColumnName = nil;
                            
                            for(int i = 0; i < [row columnCount]; i++){
                                
                                NSObject * value = [row valueWithIndex:i];
                                
                                NSString * columnName = [row columnNameWithIndex:i];
                                
                                columnName = [self columnNameWithDataColumnsDao:dataColumnsDao andAttributesRow:row  andColumnName:columnName];
                                
                                [attributeDataTypes setValue:[GPKGDataTypes name: row.attributesColumns.columns[i].dataType] forKey:columnName];
                                if(value != nil){
                                    [values setObject:value forKey:columnName];
                                }
                            }
                            
                            GPKGFeatureRowData * attributeRowData = [[GPKGFeatureRowData alloc] initWithValues:values andGeometryColumnName:geometryColumnName];
                            GeoPackageFeatureItem *featureItem = [[GeoPackageFeatureItem alloc] initWithFeatureId:row.idValue featureRowData: attributeRowData featureDataTypes: attributeDataTypes coordinate:coordinate layerName: [self getName] icon:nil style: nil mediaRows:attributeMedias attributeRows:nil];
                            [attributeFeatureRowData addObject:featureItem];
                        }
                        
                        GPKGFeatureStyle *featureStyle = [styles featureStyleWithFeature:featureRow];
                        UIImage *image = nil;
                        if ([featureStyle hasIcon]){
                            GPKGIconRow *icon = featureStyle.icon;
                            image = icon.dataImage;
                        }
                        GPKGStyleRow *style = [featureStyle style];
                                                
                        GeoPackageFeatureItem *featureItem = [[GeoPackageFeatureItem alloc] initWithFeatureId:featureId featureRowData: featureRowData featureDataTypes: featureDataTypes coordinate:coordinate layerName: [self getName] icon:image style: style mediaRows:medias attributeRows:attributeFeatureRowData];
                        [featureItems addObject:featureItem];
                    }
                }
            }
            
        }
        @catch (NSException *e) {
            NSLog(@"Build Map Click Message Error: %@", [e description]);
        }
    }
    
    return featureItems;
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

-(GPKGDataColumnsDao *) dataColumnsDao: (GPKGConnection *) database {
    
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

//
//  GeoPackageFeatureTableCacheOverlay.m
//  MAGE
//
//  Created by Brian Osborn on 12/18/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//
//

import geopackage_ios
import ExceptionCatcher

extension GPKGFeatureIndexResults: Sequence {
    public func makeIterator() -> NSFastEnumerationIterator {
        return NSFastEnumerationIterator(self)
    }
}

class GeoPackageFeatureTableCacheOverlay: GeoPackageTableCacheOverlay {
    static let GEO_PACKAGE_FEATURE_TABLE_MAX_ZOOM: Int = 21
    
    var featureOverlayQuery: GPKGFeatureOverlayQuery?
    var indexed: Bool = false
    var geometryType: SFGeometryType
    var shapes: [NSNumber: GPKGMapShape] = [:]
    var linkedTiles: [GeoPackageTileTableCacheOverlay] = []
    
    init(
        name: String,
        geoPackage: String,
        cacheName: String,
        count: Int,
        minZoom: Int,
        indexed: Bool,
        geometryType: SFGeometryType
    ) {
        self.indexed = indexed
        self.geometryType = geometryType
        super.init(
            name: name,
            geoPackage: geoPackage,
            cacheName: cacheName,
            type: CacheOverlayType.GEOPACKAGE_FEATURE_TABLE,
            count: count,
            minZoom: minZoom,
            maxZoom: GeoPackageFeatureTableCacheOverlay.GEO_PACKAGE_FEATURE_TABLE_MAX_ZOOM
        )
        self.iconImageName = "marker_outline"
    }
    
    public override func removeFromMap(mapView: MKMapView) {
        for shape in shapes.values {
            shape.remove(from: mapView)
        }
        shapes.removeAll()
        super.removeFromMap(mapView: mapView)
        for linkedTileTable in linkedTiles {
            linkedTileTable.removeFromMap(mapView: mapView)
        }
    }
    
    public override func getInfo() -> String? {
        var minZoom = self.minZoom
        var maxZoom = self.maxZoom
        for linkedTileTable in linkedTiles {
            minZoom = min(minZoom, linkedTileTable.minZoom)
            maxZoom = max(maxZoom, linkedTileTable.maxZoom)
        }
        return "\(count) feature\(count == 1 ? "s" : ""), zoom: \(minZoom) - \(maxZoom)"
    }
    
    public override func onMapClick(locationCoordinates: CLLocationCoordinate2D, mapView: MKMapView) -> String? {
        guard let featureOverlayQuery = featureOverlayQuery else { return nil }
        
        return featureOverlayQuery.buildMapClickMessage(with: locationCoordinates, andMapView: mapView)
    }
    
    public func getFeatureTableData(locationCoordinate: CLLocationCoordinate2D, mapView: MKMapView) -> GPKGFeatureTableData? {
        guard let featureOverlayQuery = featureOverlayQuery else { return nil }
        return featureOverlayQuery.buildMapClickTableData(with: locationCoordinate, andMapView: mapView)
    }
    
    private func verifyIndexAndShouldReturnInformation(location: CLLocationCoordinate2D, zoom: Double) -> Bool {
        guard let featureOverlayQuery = featureOverlayQuery else { return false }
        do {
            return try ExceptionCatcher.catch {
                return featureOverlayQuery.isIndexed()
                && (featureOverlayQuery.maxFeaturesInfo || featureOverlayQuery.featuresInfo)
                && featureOverlayQuery.on(atZoom: zoom, andLocationCoordinate: location)
            }
        } catch {
            NSLog("Verify index exception \(error)")
        }
        return false
    }
    
    private func buildFeatureItems(
        results: GPKGFeatureIndexResults,
        defaultCoordinate: CLLocationCoordinate2D
    ) -> [GeoPackageFeatureItem] {
        guard let featureOverlayQuery = featureOverlayQuery else { return [] }
        
        do {
            return try ExceptionCatcher.catch {
                var featureItems: [GeoPackageFeatureItem] = []
                guard let geoPackage = GPKGGeoPackageManager().open(self.geoPackage) else { return [] }
                for case let featureRow as GPKGFeatureRow in results {
                    if let featureItem = GeoPackageFeatureItem(
                        featureRow: featureRow,
                        geoPackage: geoPackage,
                        layerName: name,
                        projection: featureOverlayQuery.featureTiles().featureDao().projection
                    ) {
                        featureItems.append(featureItem)
                    }
                }
                return featureItems
            }
        } catch {
            NSLog("Build feature items error \(error)")
        }
        return []
    }
    
    private func buildFeatureKeys(results: GPKGFeatureIndexResults) -> [GeoPackageFeatureKey] {
        do {
            return try ExceptionCatcher.catch {
                var featureKeys: [GeoPackageFeatureKey] = []
                for case let featureRow as GPKGFeatureRow in results {
                    let featureId = featureRow.idValue()
                    let tableName = featureRow.tableName() ?? ""
                    featureKeys.append(
                        GeoPackageFeatureKey(
                            geoPackageName: geoPackage,
                            featureId: Int(featureId),
                            layerName: name,
                            tableName: tableName
                        )
                    )
                }
                return featureKeys
            }
        } catch {
            NSLog("Build feature keys error \(error)")
        }
        return []
    }
    
    public func getFeaturesNear(location: CLLocationCoordinate2D, mapView: MKMapView) -> [GeoPackageFeatureItem] {
        guard let featureOverlayQuery = featureOverlayQuery else { return [] }

        let zoom = GPKGMapUtils.currentZoom(with: mapView)
        if !verifyIndexAndShouldReturnInformation(location: location, zoom: zoom) {
            return []
        }
        
        do {
            return try ExceptionCatcher.catch {
                var featureItems: [GeoPackageFeatureItem] = []
                let tileFeatureCount = featureOverlayQuery.tileFeatureCount(with: location, andDoubleZoom: zoom)
                if featureOverlayQuery.moreThanMaxFeatures(tileFeatureCount) {
                    // found more than the maximum amount of features.  Send back a messiage indicating that
                    featureItems.append(
                        GeoPackageFeatureItem(
                            maxFeaturesReached: true,
                            featureCount: Int(tileFeatureCount),
                            geoPackageName: geoPackage,
                            layerName: name,
                            tableName: featureOverlayQuery.featureTiles().featureDao().tableName
                        )
                    )
                    return featureItems
                }
                if let results = getFeatureResultsNear(location: location, mapView: mapView) {
                    return buildFeatureItems(results: results, defaultCoordinate: location)
                }
                return []
            }
        } catch {
            NSLog("Get features near error \(error)")
        }
        
        return []
    }
    
    @MainActor
    public func getFeatureKeysNear(location: CLLocationCoordinate2D, mapView: MKMapView) -> [GeoPackageFeatureKey] {
        guard let featureOverlayQuery = featureOverlayQuery else { return [] }
        
        do {
            return try ExceptionCatcher.catch {
                let zoom = GPKGMapUtils.currentZoom(with: mapView)
                if !verifyIndexAndShouldReturnInformation(location: location, zoom: zoom) {
                    return []
                }
                
                let tileFeatureCount = featureOverlayQuery.tileFeatureCount(with: location, andDoubleZoom: zoom)
                
                if featureOverlayQuery.moreThanMaxFeatures(tileFeatureCount) {
                    if featureOverlayQuery.maxFeaturesInfo {
                        return [
                            GeoPackageFeatureKey(
                                geoPackageName: geoPackage,
                                featureCount: Int(tileFeatureCount),
                                layerName: name,
                                tableName: name
                            )
                        ]
                    }
                }
                
                if let results = getFeatureResultsNear(location: location, mapView: mapView) {
                    return buildFeatureKeys(results: results)
                }
                return []
            }
        } catch {
            NSLog("Get feature keys near failed: \(error)")
        }
        return []
    }
    
    private func getFeatureResultsNear(location: CLLocationCoordinate2D, mapView: MKMapView) -> GPKGFeatureIndexResults? {
        guard let featureOverlayQuery = featureOverlayQuery else { return nil }
        
        let zoom = GPKGMapUtils.currentZoom(with: mapView)
        
        let boundingBox = GPKGMapUtils.buildClickBoundingBox(
            with: location,
            andMapView: mapView,
            andScreenPercentage: featureOverlayQuery.screenClickPercentage
        )
        
        do {
            return try ExceptionCatcher.catch {
                let tileFeatureCount = featureOverlayQuery.tileFeatureCount(with: location, andDoubleZoom: zoom)
                if !featureOverlayQuery.moreThanMaxFeatures(tileFeatureCount) {
                    if featureOverlayQuery.featuresInfo {
                        return featureOverlayQuery.queryFeatures(with: boundingBox)
                    }
                }
                return nil
            }
        } catch {
            NSLog("Build map click message error: \(error)")
        }
        return nil
    }
    
    public func addShape(id: NSNumber, shape: GPKGMapShape) {
        shapes[id] = shape
    }
    
    public func removeShape(id: NSNumber) -> GPKGMapShape? {
        let shape = shapes[id]
        shapes.removeValue(forKey: id)
        return shape
    }
    
    public func removeShapeFromMap(id: NSNumber, mapView: MKMapView) -> GPKGMapShape? {
        let shape = shapes[id]
        if let shape {
            shape.remove(from: mapView)
        }
        return shape
    }
    
    public func addLinkedTileTable(tileTable: GeoPackageTileTableCacheOverlay) {
        linkedTiles.append(tileTable)
    }
    
    public func getLinkedTileTables() -> [GeoPackageTileTableCacheOverlay] {
        linkedTiles
    }
}

//-(instancetype) initWithName: (NSString *) name andGeoPackage: (NSString *) geoPackage andCacheName: (NSString *) cacheName andCount: (int) count andMinZoom: (int) minZoom andIndexed: (BOOL) indexed andGeometryType: (enum SFGeometryType) geometryType{
//    self = [super initWithName:name andGeoPackage:geoPackage andCacheName:cacheName andType:GEOPACKAGE_FEATURE_TABLE andCount:count andMinZoom:minZoom andMaxZoom:GEO_PACKAGE_FEATURE_TABLE_MAX_ZOOM];
//    if(self){
//        self.shapes = [[NSMutableDictionary alloc] init];
//        self.indexed = indexed;
//        self.geometryType = geometryType;
//        self.linkedTiles = [[NSMutableArray alloc] init];
//    }
//    return self;
//}
//
//-(void) removeFromMap: (MKMapView *) mapView{
//    for(GPKGMapShape * shape in [self.shapes allValues]){
//        [shape removeFromMapView: mapView];
//    }
//    [self.shapes removeAllObjects];
//    [super removeFromMap: mapView];
//    
//    for(GeoPackageTileTableCacheOverlay * linkedTileTable in self.linkedTiles){
//        [linkedTileTable removeFromMap:mapView];
//    }
//}
//
//-(NSString *) getIconImageName{
//    return @"marker_outline";
//}
//
//-(NSString *) getInfo{
//    int minZoom = [self getMinZoom];
//    int maxZoom = [self getMaxZoom];
//    for(GeoPackageTileTableCacheOverlay * linkedTileTable in self.linkedTiles){
//        minZoom = MIN(minZoom, [linkedTileTable getMinZoom]);
//        maxZoom = MAX(maxZoom, [linkedTileTable getMaxZoom]);
//    }
//    return [NSString stringWithFormat:@"%d feature%@, zoom: %d - %d", [self getCount], [self getCount] == 1 ? @"" : @"s", minZoom, maxZoom];
//}
//
//-(NSString *) onMapClickWithLocationCoordinate: (CLLocationCoordinate2D) locationCoordinate andMap: (MKMapView *) mapView{
//    NSString * message = nil;
//    
//    if(self.featureOverlayQuery != nil){
//        message = [self.featureOverlayQuery buildMapClickMessageWithLocationCoordinate:locationCoordinate andMapView:mapView];
//    }
//    
//    return message;
//}
//
//-(GPKGFeatureTableData *) getFeatureTableDataWithLocationCoordinate: (CLLocationCoordinate2D) locationCoordinate andMap: (MKMapView *) mapView{
//    GPKGFeatureTableData * featureTableData = nil;
//    if(self.featureOverlayQuery != nil){
//        
//        featureTableData = [self.featureOverlayQuery buildMapClickTableDataWithLocationCoordinate:locationCoordinate andMapView:mapView];
//    }
//    
//    return featureTableData;
//}
//
//- (BOOL) verifyIndexAndShouldReturnInformationAtLocation: (CLLocationCoordinate2D) tapLocation andZoom: (double) zoom {
//    @try {
//        return [self.featureOverlayQuery isIndexed] 
//            && (self.featureOverlayQuery.maxFeaturesInfo || self.featureOverlayQuery.featuresInfo)
//            && [self.featureOverlayQuery onAtZoom:zoom andLocationCoordinate:tapLocation];
//        
//    } @catch (NSException *e) {
//        NSLog(@"Verify index exception: %@", [e description]);
//    }
//    return FALSE;
//}
//
//- (NSArray<GeoPackageFeatureItem *> *) buildFeatureItems: (GPKGFeatureIndexResults *) results
//                                       defaultCoordinate: (CLLocationCoordinate2D) defaultCoordinate
//{
//    NSMutableArray<GeoPackageFeatureItem *> *featureItems = [[NSMutableArray alloc] init];
//    
//    @try {
//        
//        GPKGGeoPackage *geoPackage = [[GPKGGeoPackageFactory manager] open:[self getGeoPackage]];
//        for (GPKGFeatureRow *featureRow in results) {
//            GeoPackageFeatureItem *featureItem = [[GeoPackageFeatureItem alloc] initWithFeatureRow:featureRow geoPackage:geoPackage layerName:[self getName] projection:self.featureOverlayQuery.featureTiles.featureDao.projection];
//            if (featureItem != nil) {
//                [featureItems addObject:featureItem];
//            }
//        }
//    } @catch (NSException *e) {
//        NSLog(@"Build Map Click Message Error: %@", [e description]);
//    }
//    return featureItems;
//}
//
//- (NSArray<GeoPackageFeatureKey *> *) buildFeatureKeys: (GPKGFeatureIndexResults *) results {
//    NSMutableArray<GeoPackageFeatureKey *> *featureKeys = [[NSMutableArray alloc] init];
//    
//    @try {
//        for (GPKGFeatureRow *featureRow in results) {
//            int featureId = featureRow.idValue;
//            NSString * tableName = featureRow.tableName;
//            [featureKeys addObject: [[GeoPackageFeatureKey alloc] initWithGeoPackageName:[self getGeoPackage]
//                                                                               featureId:featureId
//                                                                               layerName:[self getName]
//                                                                               tableName:tableName
//                                    ]
//            ];
//        }
//    } @catch (NSException *e) {
//        NSLog(@"Build Map Click Message Error: %@", [e description]);
//    }
//    return featureKeys;
//}
//
//- (NSArray<GeoPackageFeatureItem *> *) getFeaturesNearTap: (CLLocationCoordinate2D) tapLocation andMap: (MKMapView *) mapView {
//    NSMutableArray<GeoPackageFeatureItem *> *featureItems = [[NSMutableArray alloc] init];
//    
//    // Get the zoom level
//    double zoom = [GPKGMapUtils currentZoomWithMapView:mapView];
//    if (![self verifyIndexAndShouldReturnInformationAtLocation:tapLocation andZoom:zoom]) {
//        return featureItems;
//    }
//    
//    @try {
//        // Get the number of features in the tile location
//        int tileFeatureCount = [self.featureOverlayQuery tileFeatureCountWithLocationCoordinate:tapLocation andDoubleZoom:zoom];
//        
//        // If more than a configured max features to drawere
//        if([self.featureOverlayQuery moreThanMaxFeatures:tileFeatureCount]){
//            
//            // Build the max features message
//            if(self.featureOverlayQuery.maxFeaturesInfo){
//                GeoPackageFeatureItem *featureItem = [[GeoPackageFeatureItem alloc]
//                                                      initWithMaxFeaturesReached:true
//                                                      featureCount:tileFeatureCount
//                                                      geoPackageName: [self getGeoPackage]
//                                                      layerName:[self getName]
//                                                      tableName: self.featureOverlayQuery.featureTiles.featureDao.tableName];
//                [featureItems addObject:featureItem];
//                return featureItems;
//            }
//        }
//        
//        
//        GPKGFeatureIndexResults * results = [self getFeatureResultsNearTap:tapLocation andMap:mapView];
//        [featureItems addObjectsFromArray: [self buildFeatureItems:results defaultCoordinate:tapLocation]];
//    } @catch (NSException *e) {
//        NSLog(@"Build Map Click Message Error: %@", [e description]);
//    }
//    
//    return featureItems;
//}
//
//- (NSArray<GeoPackageFeatureKey *> *) getFeatureKeysNearTap: (CLLocationCoordinate2D) tapLocation andMap: (MKMapView *) mapView {
//    NSMutableArray<GeoPackageFeatureKey *> *featureKeys = [[NSMutableArray alloc] init];
//    
//    // Get the zoom level
//    double zoom = [GPKGMapUtils currentZoomWithMapView:mapView];
//    if (![self verifyIndexAndShouldReturnInformationAtLocation:tapLocation andZoom:zoom]) {
//        return featureKeys;
//    }
//    
//    @try {
//        // Get the number of features in the tile location
//        int tileFeatureCount = [self.featureOverlayQuery tileFeatureCountWithLocationCoordinate:tapLocation andDoubleZoom:zoom];
//        
//        // If more than a configured max features to drawere
//        if([self.featureOverlayQuery moreThanMaxFeatures:tileFeatureCount]){
//            
//            // Build the max features message
//            if(self.featureOverlayQuery.maxFeaturesInfo){
//                GeoPackageFeatureKey *featureKey = [[GeoPackageFeatureKey alloc] initWithGeoPackageName:[self getGeoPackage] featureCount:tileFeatureCount layerName:[self getName] tableName: [self getName]];
//                [featureKeys addObject:featureKey];
//                return featureKeys;
//            }
//        }
//        
//        GPKGFeatureIndexResults * results = [self getFeatureResultsNearTap:tapLocation andMap:mapView];
//        [featureKeys addObjectsFromArray: [self buildFeatureKeys:results]];
//    } @catch (NSException *e) {
//        NSLog(@"Build Map Click Message Error: %@", [e description]);
//    }
//    
//    return featureKeys;
//}
//
//// all checks to ensure we should query should have already been before this method is called
//- (nullable GPKGFeatureIndexResults *) getFeatureResultsNearTap: (CLLocationCoordinate2D) tapLocation andMap: (MKMapView *) mapView {
//    NSMutableArray<GeoPackageFeatureItem *> *featureItems = [[NSMutableArray alloc] init];
//    // Get the zoom level
//    double zoom = [GPKGMapUtils currentZoomWithMapView:mapView];
//    
//    // Build a bounding box to represent the click location
//    GPKGBoundingBox * boundingBox = [GPKGMapUtils buildClickBoundingBoxWithLocationCoordinate:tapLocation andMapView:mapView andScreenPercentage:self.featureOverlayQuery.screenClickPercentage];
//    
//    
//    @try {
//        // Get the number of features in the tile location
//        int tileFeatureCount = [self.featureOverlayQuery tileFeatureCountWithLocationCoordinate:tapLocation andDoubleZoom:zoom];
//        
//        // If more than a configured max features to drawere
//        if([self.featureOverlayQuery moreThanMaxFeatures:tileFeatureCount]){
//            
//            // Build the max features message
//            if(self.featureOverlayQuery.maxFeaturesInfo){
//                GeoPackageFeatureItem *featureItem = [[GeoPackageFeatureItem alloc]
//                                                      initWithMaxFeaturesReached:true
//                                                      featureCount:tileFeatureCount
//                                                      geoPackageName: [self getGeoPackage]
//                                                      layerName:[self getName]
//                                                      tableName: self.featureOverlayQuery.featureTiles.featureDao.tableName];
//                [featureItems addObject:featureItem];
//            }
//        }
//        // Else, query for the features near the click
//        else if(self.featureOverlayQuery.featuresInfo){
//            // Query for results and build the message
//            NSLog(@"Bounding box %@", boundingBox);
//            return [self.featureOverlayQuery queryFeaturesWithBoundingBox:boundingBox inProjection:nil];
//        }
//    } @catch (NSException *e) {
//        NSLog(@"Build Map Click Message Error: %@", [e description]);
//    }
//    return nil;
//}
//
//
//-(NSString *) columnNameWithDataColumnsDao: (GPKGDataColumnsDao *) dataColumnsDao andFeatureRow: (GPKGFeatureRow *) featureRow andColumnName: (NSString *) columnName{
//    
//    NSString * newColumnName = columnName;
//    
//    if(dataColumnsDao != nil){
//        GPKGDataColumns * dataColumn = [dataColumnsDao dataColumnByTableName:featureRow.table.tableName andColumnName:columnName];
//        if(dataColumn != nil){
//            newColumnName = dataColumn.name;
//        }
//    }
//    
//    return newColumnName;
//}
//
//-(NSString *) columnNameWithDataColumnsDao: (GPKGDataColumnsDao *) dataColumnsDao andAttributesRow: (GPKGAttributesRow *) attributeRow andColumnName: (NSString *) columnName{
//    
//    NSString * newColumnName = columnName;
//    
//    if(dataColumnsDao != nil){
//        GPKGDataColumns * dataColumn = [dataColumnsDao dataColumnByTableName:attributeRow.table.tableName andColumnName:columnName];
//        if(dataColumn != nil){
//            newColumnName = dataColumn.name;
//        }
//    }
//    
//    return newColumnName;
//}
//
//-(nullable GPKGDataColumnsDao *) dataColumnsDao: (GPKGConnection *) database {
//    
//    GPKGDataColumnsDao * dataColumnsDao = [[GPKGDataColumnsDao alloc] initWithDatabase:database];
//    
//    if(![dataColumnsDao tableExists]){
//        dataColumnsDao = nil;
//    }
//    
//    return dataColumnsDao;
//}
//
//-(BOOL) getIndexed{
//    return self.indexed;
//}
//
//-(enum SFGeometryType) getGeometryType{
//    return self.geometryType;
//}
//
//-(void) addShapeWithId: (NSNumber *) id andShape: (GPKGMapShape *) shape{
//    @try {
//    [self.shapes setObject:shape forKey:id];
//    }
//    @catch (NSException *e) {
//        NSLog(@"Failure adding shape to map %@", e);
//    }
//}
//
//-(GPKGMapShape *) removeShapeWithId: (NSNumber *) id{
//    GPKGMapShape * shape = [self.shapes objectForKey:id];
//    if(shape != nil){
//        [self.shapes removeObjectForKey:id];
//    }
//    return shape;
//}
//
//-(GPKGMapShape *) removeShapeFromMapWithId: (NSNumber *) id fromMapView: (MKMapView *) mapView{
//    GPKGMapShape * shape = [self removeShapeWithId: id];
//    if(shape != nil){
//        [shape removeFromMapView:mapView];
//    }
//    return shape;
//}
//
//-(void) addLinkedTileTable: (GeoPackageTileTableCacheOverlay *) tileTable{
//    [self.linkedTiles addObject:tileTable];
//}
//
//-(NSArray<GeoPackageTileTableCacheOverlay *> *) getLinkedTileTables{
//    return self.linkedTiles;
//}
//
//@end

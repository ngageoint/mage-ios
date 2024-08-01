//
//  GeoPackageFeatureTableCacheOverlay.h
//  MAGE
//
//  Created by Brian Osborn on 12/18/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "GeoPackageTableCacheOverlay.h"
#import "GPKGFeatureOverlayQuery.h"
#import "GPKGMapShape.h"
#import "GeoPackageTileTableCacheOverlay.h"
#import "MAGE-Swift.h"


extern NSInteger const GEO_PACKAGE_FEATURE_TABLE_MAX_ZOOM;

@interface GeoPackageFeatureTableCacheOverlay : GeoPackageTableCacheOverlay

/**
 *  Used to query the backing feature table
 */
@property (strong, nonatomic) GPKGFeatureOverlayQuery * featureOverlayQuery;

/**
 *  Initializer
 *
 *  @param name         GeoPackage table name
 *  @param geoPackage   GeoPackage name
 *  @param cacheName    Cache name
 *  @param count        count
 *  @param minZoom      min zoom level
 *  @param indexed      indexed flag
 *  @param geometryType geometry type
 *
 *  @return new instance
 */
-(instancetype) initWithName: (NSString *) name andGeoPackage: (NSString *) geoPackage andCacheName: (NSString *) cacheName andCount: (int) count andMinZoom: (int) minZoom andIndexed: (BOOL) indexed andGeometryType: (enum SFGeometryType) geometryType;

/**
 *  Get the indexed value
 *
 *  @return true if indexed
 */
-(BOOL) getIndexed;

/**
 *  Get the geometry type
 *
 *  @return geometry type
 */
-(enum SFGeometryType) getGeometryType;

/**
 *  Add a shape
 *
 *  @param id    id
 *  @param shape shape
 */
-(void) addShapeWithId: (NSNumber *) id andShape: (GPKGMapShape *) shape;

/**
 *  Remove a shape
 *
 *  @param id id
 *
 *  @return shape
 */
-(GPKGMapShape *) removeShapeWithId: (NSNumber *) id;

/**
 *  Remove a shape from the map view
 *
 *  @param id      id
 *  @param mapView map view
 *
 *  @return shape
 */
-(GPKGMapShape *) removeShapeFromMapWithId: (NSNumber *) id fromMapView: (MKMapView *) mapView;

/**
 *  Add a linked tile table cache overlay
 *
 *  @param tileTable  tile table cache overlay
 */
-(void) addLinkedTileTable: (GeoPackageTileTableCacheOverlay *) tileTable;

/**
 *  Get the linked tile table cache overlays
 *
 *  @return linked tile table cache overlays
 */
-(NSArray<GeoPackageTileTableCacheOverlay *> *) getLinkedTileTables;

-(GPKGFeatureTableData *) getFeatureTableDataWithLocationCoordinate: (CLLocationCoordinate2D) locationCoordinate andMap: (MKMapView *) mapView;
- (NSArray<GeoPackageFeatureItem *> *) getFeaturesNearTap: (CLLocationCoordinate2D) tapLocation andMap: (MKMapView *) mapView;
- (NSArray<GeoPackageFeatureKey *> *) getFeatureKeysNearTap: (CLLocationCoordinate2D) tapLocation andMap: (MKMapView *) mapView;

@end

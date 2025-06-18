//
//  GeoPackage.h
//  MAGE
//
//  Created by Daniel Barela on 1/31/22.
//  Copyright © 2022 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GeoPackageTileTableCacheOverlay.h"

@class GeoPackageFeatureItem;

NS_ASSUME_NONNULL_BEGIN

@interface GeoPackage : NSObject

- (id) initWithMapView: (MKMapView *) mapView;
- (void) updateCacheOverlaysSynchronized:(NSArray<CacheOverlay *> *) cacheOverlays;
- (NSArray<GeoPackageFeatureItem *>*) getFeaturesAtTap:(CLLocationCoordinate2D) tapCoord;

@end

NS_ASSUME_NONNULL_END

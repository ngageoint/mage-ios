//
//  MapUtils.h
//  MAGE
//
//  Created by Brian Osborn on 5/4/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

/**
 * Map utilities
 */
@interface MapUtils : NSObject

/**
 * Get the map point to line distance tolerance
 *
 * @param mapView map view
 * @return tolerance
 */
+(double) lineToleranceWithMapView: (MKMapView *) mapView;

@end

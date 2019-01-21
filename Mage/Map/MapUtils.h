//
//  MapUtils.h
//  MAGE
//
//  Created by Brian Osborn on 5/4/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "StyledPolygon.h"
#import "StyledPolyline.h"
#import "SFPolygon.h"

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

+ (BOOL) rect: (CGRect) r ContainsLineStart: (CGPoint) lineStart andLineEnd: (CGPoint) lineEnd;

+ (StyledPolyline *) generatePolyline:(NSMutableArray *) path;

+ (StyledPolygon *) generatePolygon:(NSMutableArray *) coordinates;

+ (BOOL) line1Start: (CGPoint) line1Start andEnd: (CGPoint) line1End intersectsLine2Start: (CGPoint) line2Start andEnd: (CGPoint) line2End;

+ (BOOL) polygonHasIntersections: (SFPolygon *) polygon;

@end

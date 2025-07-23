//
//  MapUtils.m
//  MAGE
//
//  Created by Brian Osborn on 5/4/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapUtils.h"
@import SimpleFeatures;
@import GeoPackage;

@implementation MapUtils

+(double) lineToleranceWithMapView: (MKMapView *) mapView{
 
    CLLocationCoordinate2D l1 = [mapView convertPoint:CGPointMake(0,0) toCoordinateFromView:mapView];
    CLLocation *ll1 = [[CLLocation alloc] initWithLatitude:l1.latitude longitude:l1.longitude];
    CLLocationCoordinate2D l2 = [mapView convertPoint:CGPointMake(0,500) toCoordinateFromView:mapView];
    CLLocation *ll2 = [[CLLocation alloc] initWithLatitude:l2.latitude longitude:l2.longitude];
    double mpp = [ll1 distanceFromLocation:ll2] / 500.0;
    
    double tolerance = mpp * sqrt(2.0) * 20.0 * [[UIScreen mainScreen] scale];
    
    return tolerance;
}

+ (BOOL)polygonHasIntersections:(SFPolygon *)polygon {
    // Iterate over each ring in the polygon
    for (SFLineString *ring1 in polygon.rings) {
        NSUInteger ring1PointCount = [ring1 numPoints];
        SFPoint *lastPoint = ring1.points[ring1PointCount - 1]; // last point for closure checks
        
        // Compare each ring against every ring (including itself)
        for (SFLineString *ring2 in polygon.rings) {
            NSUInteger ring2PointCount = [ring2 numPoints];
            
            // Check all segments in ring1
            for (NSUInteger i = 0; i < ring1PointCount - 1; i++) {
                SFPoint *p1Start = ring1.points[i];
                SFPoint *p1End = ring1.points[i + 1];
                
                // Check all segments in ring2
                for (NSUInteger k = 0; k < ring2PointCount - 1; k++) {
                    SFPoint *p2Start = ring2.points[k];
                    SFPoint *p2End = ring2.points[k + 1];
                    
                    // Skip comparing a segment with itself or immediate neighbors
                    if (ring1 == ring2 && labs((NSInteger)i - (NSInteger)k) <= 1) continue;
                    
                    // Skip first and last segment overlap in a closed ring
                    if (ring1 == ring2 && i == 0 && k == ring1PointCount - 2 &&
                        [p1Start.x isEqual:lastPoint.x] && [p1Start.y isEqual:lastPoint.y]) {
                        continue;
                    }
                    
                    // Check for intersection
                    BOOL intersects = [MapUtils line1Start:CGPointMake(p1Start.x.doubleValue, p1Start.y.doubleValue)
                                                    andEnd:CGPointMake(p1End.x.doubleValue, p1End.y.doubleValue)
                                        intersectsLine2Start:CGPointMake(p2Start.x.doubleValue, p2Start.y.doubleValue)
                                                     andEnd:CGPointMake(p2End.x.doubleValue, p2End.y.doubleValue)];
                    
                    if (intersects) return YES; // Found intersection, early exit
                }
            }
        }
    }
    return NO; // No intersections found
}


+ (BOOL) line1Start: (CGPoint) line1Start andEnd: (CGPoint) line1End intersectsLine2Start: (CGPoint) line2Start andEnd: (CGPoint) line2End {
    CGFloat q =
    //Distance between the lines' starting rows times line2's horizontal length
    (line1Start.y - line2Start.y) * (line2End.x - line2Start.x)
    //Distance between the lines' starting columns times line2's vertical length
    - (line1Start.x - line2Start.x) * (line2End.y - line2Start.y);
    CGFloat d =
    //Line 1's horizontal length times line 2's vertical length
    (line1End.x - line1Start.x) * (line2End.y - line2Start.y)
    //Line 1's vertical length times line 2's horizontal length
    - (line1End.y - line1Start.y) * (line2End.x - line2Start.x);
    
    if( d == 0 )
        return NO;
    
    CGFloat r = q / d;
    
    q =
    //Distance between the lines' starting rows times line 1's horizontal length
    (line1Start.y - line2Start.y) * (line1End.x - line1Start.x)
    //Distance between the lines' starting columns times line 1's vertical length
    - (line1Start.x - line2Start.x) * (line1End.y - line1Start.y);
    
    CGFloat s = q / d;
    if( r < 0 || r > 1 || s < 0 || s > 1 )
        return NO;
    
    return YES;
}

+ (BOOL) rect: (CGRect) r ContainsLineStart: (CGPoint) lineStart andLineEnd: (CGPoint) lineEnd {
    /*Test whether the line intersects any of:
     *- the bottom edge of the rectangle
     *- the right edge of the rectangle
     *- the top edge of the rectangle
     *- the left edge of the rectangle
     *- the interior of the rectangle (both points inside)
     */
    return [MapUtils line1Start:lineStart andEnd:lineEnd intersectsLine2Start:CGPointMake(r.origin.x, r.origin.y) andEnd:CGPointMake(r.origin.x + r.size.width, r.origin.y)] ||
    [MapUtils line1Start:lineStart andEnd:lineEnd intersectsLine2Start:CGPointMake(r.origin.x + r.size.width, r.origin.y) andEnd:CGPointMake(r.origin.x + r.size.width, r.origin.y + r.size.height)] ||
    [MapUtils line1Start:lineStart andEnd:lineEnd intersectsLine2Start:CGPointMake(r.origin.x + r.size.width, r.origin.y + r.size.height) andEnd:CGPointMake(r.origin.x, r.origin.y + r.size.height)] ||
    [MapUtils line1Start:lineStart andEnd:lineEnd intersectsLine2Start:CGPointMake(r.origin.x, r.origin.y + r.size.height) andEnd:CGPointMake(r.origin.x, r.origin.y)] ||
    (CGRectContainsPoint(r, lineStart) && CGRectContainsPoint(r, lineEnd));
}

@end

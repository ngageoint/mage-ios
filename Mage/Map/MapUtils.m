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

+ (BOOL) polygonHasIntersections: (SFPolygon *) wkbPolygon {
    // Iterate over each ring (closed line string) in the polygon
    for (SFLineString *line1 in wkbPolygon.rings) {
        // Get the last point of the current ring (used for handling wrap-around edge cases)
        SFPoint *lastPoint = [line1.points objectAtIndex:[line1 numPoints] - 1];
        
        // Compare the current ring with every other ring in the polygon (including itself)
        for (SFLineString *line2 in wkbPolygon.rings) {
            // Loop through each segment of the first ring (line1)
            for (int i = 0; i < [line1 numPoints] - 1; i++) {
                // Get the start point of the current segment in line1
                SFPoint *point1 = [line1.points objectAtIndex:i];
                // Get the end point of the current segment in line1
                SFPoint *nextPoint1 = [line1.points objectAtIndex:i+1];
                
                // Loop through each segment of the second ring (line2)
                for (int k = i; k < [line2 numPoints] - 1; k++) {
                    // Get the start point of the current segment in line2
                    SFPoint *point2 = [line2.points objectAtIndex:k];
                    // Get the end point of the current segment in line2
                    SFPoint *nextPoint2 = [line2.points objectAtIndex:k+1];
                    
                    // Skip comparison if we are checking the same ring (we only want self-intersections)
                    if (line1 != line2) continue;
                    
                    // Skip adjacent segments in the same ring (they share a vertex and will always intersect)
                    if (abs(i-k) <= 1) continue;
                    
                    // Skip comparison of the first and last segment if they share the same point (closing segment)
                    if (i == 0 && k == [line1 numPoints] - 2 && point1.x == lastPoint.x && point1.y == lastPoint.y) continue;
                    
                    // Check if the two line segments (point1->nextPoint1 and point2->nextPoint2) intersect
                    BOOL intersects = [MapUtils line1Start:CGPointMake([point1.x doubleValue], [point1.y doubleValue])
                                                  andEnd:CGPointMake([nextPoint1.x doubleValue], [nextPoint1.y doubleValue])
                                      intersectsLine2Start:CGPointMake([point2.x doubleValue], [point2.y doubleValue])
                                                  andEnd:CGPointMake([nextPoint2.x doubleValue], [nextPoint2.y doubleValue])];
                    
                    // If an intersection is found, return YES immediately
                    if (intersects) return YES;
                }
            }
        }
    }
    
    // If no intersections are found after checking all segments, return NO
    return NO;
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

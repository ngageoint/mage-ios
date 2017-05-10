//
//  MapPolylineObservation.m
//  MAGE
//
//  Created by Brian Osborn on 5/1/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapPolylineObservation.h"

@interface MapPolylineObservation ()

@property (nonatomic, strong) MKPolyline *polyline;

@end

@implementation MapPolylineObservation

-(instancetype) initWithObservation: (Observation *) observation andMapShape: (GPKGMapShape *) shape{
    self = [super initWithObservation:observation andMapShape:shape];
    if(self){
        self.polyline = (MKPolyline *)shape.shape;
    }
    return self;
}

-(BOOL) isOnShapeAtLocation: (CLLocationCoordinate2D) location withTolerance: (double) tolerance andMapView: (MKMapView *) mapView{
    
    MKPolylineRenderer *polylineRenderer = (MKPolylineRenderer *)[mapView rendererForOverlay:self.polyline];
    MKMapPoint mapPoint = MKMapPointForCoordinate(location);
    CGPoint point = [polylineRenderer pointForMapPoint:mapPoint];
    CGPathRef strokedPath = CGPathCreateCopyByStrokingPath(polylineRenderer.path, NULL, tolerance, kCGLineCapRound, kCGLineJoinRound, 1);
    BOOL onShape = CGPathContainsPoint(strokedPath, NULL, point, NO);
    CGPathRelease(strokedPath);
    return onShape;

}

@end

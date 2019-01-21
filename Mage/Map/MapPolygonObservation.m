//
//  MapPolygonObservation.m
//  MAGE
//
//  Created by Brian Osborn on 5/1/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapPolygonObservation.h"
#import "GPKGMapUtils.h"

@interface MapPolygonObservation ()

@property (nonatomic, strong) MKPolygon *polygon;

@end

@implementation MapPolygonObservation

-(instancetype) initWithObservation: (Observation *) observation andMapShape: (GPKGMapShape *) shape{
    self = [super initWithObservation:observation andMapShape:shape];
    if(self){
        self.polygon = (MKPolygon *)shape.shape;
    }
    return self;
}

-(BOOL) isOnShapeAtLocation: (CLLocationCoordinate2D) location withTolerance: (double) tolerance andMapView: (MKMapView *) mapView{
    
    MKPolygonRenderer *polygonRenderer = (MKPolygonRenderer *)[mapView rendererForOverlay:self.polygon];
    MKMapPoint mapPoint = MKMapPointForCoordinate(location);
    CGPoint point = [polygonRenderer pointForMapPoint:mapPoint];
    BOOL onShape = CGPathContainsPoint(polygonRenderer.path, NULL, point, NO);
    
    // If not on the polygon, check the complementary polygon path in case it crosses -180 / 180 longitude
    if(!onShape){
        CGPathRef complementaryPath = [GPKGMapUtils complementaryWorldPathOfPolygon:self.polygon];
        onShape = CGPathContainsPoint(complementaryPath, NULL, CGPointMake(mapPoint.x, mapPoint.y), NO);
        CGPathRelease(complementaryPath);
    }
    
    return onShape;
}

@end

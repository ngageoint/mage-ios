//
//  MapShapeObservation.m
//  MAGE
//
//  Created by Brian Osborn on 5/1/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapShapeObservation.h"
#import "MapPolylineObservation.h"
#import "MapPolygonObservation.h"

@interface MapShapeObservation ()

@property (nonatomic, strong) GPKGMapShape *shape;

@end

@implementation MapShapeObservation

// TODO Geometry use this?
static BOOL const GEODESIC = NO;

+(MapShapeObservation *) createWithObservation: (Observation *) observation andMapShape: (GPKGMapShape *) shape{
    
    MapShapeObservation *observationShape = nil;
    switch (shape.shapeType) {
        case GPKG_MST_POLYLINE:
            observationShape = [[MapPolylineObservation alloc] initWithObservation:observation andMapShape:shape];
            break;
        case GPKG_MST_POLYGON:
            observationShape = [[MapPolygonObservation alloc] initWithObservation:observation andMapShape:shape];
            break;
        default:
            [NSException raise:@"Illegal Shape" format:@"Illegal Shape Type: %u", shape.shapeType];
    }
    return observationShape;
}

-(instancetype) initWithObservation: (Observation *) observation andMapShape: (GPKGMapShape *) shape{
    self = [super initWithObservation:observation];
    if(self){
        self.shape = shape;
    }
    return self;
}

-(GPKGMapShape *) shape{
    return _shape;
}

-(void) removeFromMapView: (MKMapView *) mapView{
    [_shape removeFromMapView:mapView];
}

-(void) hidden: (BOOL) hidden fromMapView: (MKMapView *) mapView{
    [_shape hidden:hidden fromMapView:mapView];
}

-(BOOL) isOnShapeWithLocation: (CLLocation *) location andTolerance: (double) tolerance{
    [NSException raise:@"No Implementation" format:@"Implementation must be provided by an extending map shape observation type"];
    return NO;
}

@end

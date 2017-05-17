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
#import "GPKGProjectionConstants.h"

@interface MapShapeObservation ()

@property (nonatomic, strong) GPKGMapShape *shape;

@end

@implementation MapShapeObservation

static float paddingPercentage = .1;

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

-(BOOL) isOnShapeAtLocation: (CLLocationCoordinate2D) location withTolerance: (double) tolerance andMapView: (MKMapView *) mapView{
    [NSException raise:@"No Implementation" format:@"Implementation must be provided by an extending map shape observation type"];
    return NO;
}

-(MKCoordinateRegion) viewRegionOfMapView: (MKMapView *) mapView{
    GPKGBoundingBox *bbox = [_shape boundingBox];
    struct GPKGBoundingBoxSize size = [bbox sizeInMeters];
    double expandedHeight = size.height + (2 * (size.height * paddingPercentage));
    double expandedWidth = size.width + (2 * (size.width * paddingPercentage));

    CLLocationCoordinate2D center = [bbox getCenter];
    MKCoordinateRegion expandedRegion = MKCoordinateRegionMakeWithDistance(center, expandedHeight, expandedWidth);

    double latitudeRange = expandedRegion.span.latitudeDelta / 2.0;

    if(expandedRegion.center.latitude + latitudeRange > PROJ_WGS84_HALF_WORLD_LAT_HEIGHT || expandedRegion.center.latitude - latitudeRange < -PROJ_WGS84_HALF_WORLD_LAT_HEIGHT){
        expandedRegion = MKCoordinateRegionMake(mapView.centerCoordinate, MKCoordinateSpanMake(180, 360));
    }
    
    return expandedRegion;
}

@end

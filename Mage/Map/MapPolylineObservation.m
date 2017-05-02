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

-(BOOL) isOnShapeWithLocation: (CLLocation *) location andTolerance: (double) tolerance{
    // TODO Geometry
    return NO;
}

@end

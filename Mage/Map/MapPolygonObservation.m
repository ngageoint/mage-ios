//
//  MapPolygonObservation.m
//  MAGE
//
//  Created by Brian Osborn on 5/1/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapPolygonObservation.h"

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

-(BOOL) isOnShapeWithLocation: (CLLocation *) location andTolerance: (double) tolerance{
    // TODO Geometry
    return NO;
}

@end

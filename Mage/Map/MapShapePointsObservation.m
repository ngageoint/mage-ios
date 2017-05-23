//
//  MapShapePointsObservation.m
//  MAGE
//
//  Created by Brian Osborn on 5/23/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapShapePointsObservation.h"

@interface MapShapePointsObservation ()

@property (nonatomic, strong) GPKGMapShapePoints *shapePoints;

@end

@implementation MapShapePointsObservation

-(instancetype) initWithObservation: (Observation *) observation andShapePoints: (GPKGMapShapePoints *) shapePoints{
    self = [super initWithObservation:observation andMapShape:shapePoints.shape];
    if(self){
        self.shapePoints = (GPKGMapShapePoints *)shapePoints;
    }
    return self;
}

-(GPKGMapShapePoints *) shapePoints{
    return _shapePoints;
}

-(void) removeFromMapView: (MKMapView *) mapView{
    [_shapePoints removeFromMapView:mapView];
}

-(void) hidden: (BOOL) hidden fromMapView: (MKMapView *) mapView{
    [_shapePoints hidden:hidden fromMapView:mapView];
}

@end

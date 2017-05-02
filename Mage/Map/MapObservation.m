//
//  MapObservation.m
//  MAGE
//
//  Created by Brian Osborn on 5/1/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapObservation.h"

@interface MapObservation ()

@property (nonatomic, strong) Observation *observation;

@end

@implementation MapObservation

-(instancetype) initWithObservation: (Observation *) observation{
    self = [super init];
    if(self){
        self.observation = observation;
    }
    return self;
}

-(Observation *) observation{
    return _observation;
}

-(void) removeFromMapView: (MKMapView *) mapView{
    [NSException raise:@"No Implementation" format:@"Implementation must be provided by an extending map observation type"];
}

-(void) hidden: (BOOL) hidden fromMapView: (MKMapView *) mapView{
    [NSException raise:@"No Implementation" format:@"Implementation must be provided by an extending map observation type"];
}

@end

//
//  ObservationAnnotation.m
//  Mage
//
//  Created by Dan Barela on 6/26/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "ObservationAnnotation.h"
#import "GeoPoint.h"

@implementation ObservationAnnotation

-(id) initWithObservation:(Observation *) observation {
	if ((self = [super init])) {
        _coordinate = ((GeoPoint *) observation.geometry).location.coordinate;
    }
    
    return self;
}

-(NSString *) title {
	return @"Observation";
}

-(NSString *) subtitle {
	return @"subtitle";
}

-(void) setCoordinate:(CLLocationCoordinate2D) coordinate {
	_coordinate = coordinate;
}

@end

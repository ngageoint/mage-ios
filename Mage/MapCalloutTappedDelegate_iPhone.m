//
//  MapCalloutTappedDelegate_iPhone.m
//  MAGE
//
//

#import "MapCalloutTappedDelegate_iPhone.h"
#import "User.h"
#import "Observation.h"

@implementation MapCalloutTappedDelegate_iPhone

-(void) calloutTapped:(id) calloutItem {
    if ([calloutItem isKindOfClass:[User class]]) {
        [self.userMapCalloutTappedDelegate calloutTapped:calloutItem];
    } else if ([calloutItem isKindOfClass:[Observation class]]) {
        [self.observationMapCalloutTappedDelegate calloutTapped:calloutItem];
    }
}

@end

//
//  MapCalloutTappedDelegate_iPhone.m
//  MAGE
//
//

#import "MapCalloutTappedSegueDelegate.h"
#import "User.h"
#import "Observation.h"

@implementation MapCalloutTappedSegueDelegate

-(void) calloutTapped:(id) calloutItem {
    [self.viewController performSegueWithIdentifier:self.segueIdentifier sender:calloutItem];
}

@end

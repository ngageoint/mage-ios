//
//  MapCalloutTappedDelegate_iPhone.m
//  MAGE
//
//

#import "MapCalloutTappedSegueDelegate.h"
#import "User.h"
#import "observation.h"

@implementation MapCalloutTappedSegueDelegate

-(void) calloutTapped:(id) calloutItem {
    [self.viewController performSegueWithIdentifier:self.segueIdentifier sender:calloutItem];
}

@end

//
//  MapCalloutTappedDelegate_iPhone.m
//  MAGE
//
//

#import "MapCalloutTappedSegueDelegate.h"
#import "User.h"
#import "Observation.h"
#import "FeedItem.h"
#import "MAGE-Swift.h"

@implementation MapCalloutTappedSegueDelegate

-(void) calloutTapped:(id) calloutItem {
    if ([calloutItem isKindOfClass:[FeedItem class]]) {
        [self.viewController.navigationController pushViewController:[[FeedItemViewViewController alloc] initWithFeedItem:calloutItem] animated:true];
    } else {
        [self.viewController performSegueWithIdentifier:self.segueIdentifier sender:calloutItem];
    }
}

@end

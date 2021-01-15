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
        [self.viewController.navigationController pushViewController:[[FeedItemViewController alloc] initWithFeedItem:calloutItem] animated:true];
    } else if ([calloutItem isKindOfClass:[User class]]) {
        UserViewController *uvc = [[UserViewController alloc] initWithUser:calloutItem scheme:[MAGEScheme scheme]];
        [self.viewController.navigationController pushViewController:uvc animated:YES];
    } else if ([calloutItem isKindOfClass:[Observation class]]) {
        ObservationViewCardCollectionViewController *ovc = [[ObservationViewCardCollectionViewController alloc] initWithObservation:calloutItem scheme:self.scheme];
        [self.viewController.navigationController pushViewController:ovc animated:YES];
    }
}

@end

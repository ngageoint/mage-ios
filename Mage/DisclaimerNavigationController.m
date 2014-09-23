//
//  DisclaimerNavigationController.m
//  Mage
//
//  Created by Billy Newman on 7/14/14.
//

#import "DisclaimerNavigationController.h"

@implementation DisclaimerNavigationController

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString *segueIdentifier = [segue identifier];
    if ([segueIdentifier isEqualToString:@"DisplayLoginSegue"]) {
        id destinationController = [segue destinationViewController];
		[destinationController setManagedObjectContext:_managedObjectContext];
        [destinationController setLocationFetchService:_locationFetchService];
        [destinationController setObservationFetchService:_observationFetchService];
    }
}

@end

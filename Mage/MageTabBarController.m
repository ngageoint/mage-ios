//
//  MageTabBarController.m
//  MAGE
//
//

#import "MageTabBarController.h"
#import "MeViewController.h"
#import "ObservationViewController_iPad.h"

@implementation MageTabBarController

- (void) prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    UINavigationController *navigationController = [self navigationController];
    [navigationController popToRootViewControllerAnimated:NO];
    
    if ([[segue identifier] isEqualToString:@"DisplayPersonFromMapSegue"]) {
        MeViewController *destination = (MeViewController *)[segue destinationViewController];
        [destination setUser:sender];
    } else if ([[segue identifier] isEqualToString:@"DisplayObservationFromMapSegue"]) {
        ObservationViewController_iPad *destination = (ObservationViewController_iPad *)[segue destinationViewController];
        [destination setObservation:sender];
    } else if ([[segue identifier] isEqualToString:@"DisplayFeedItemFromMapSeque"]) {
        NSLog(@"Feed item tapped segue");
    }
}

@end

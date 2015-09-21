//
//  MageTabBarController.m
//  MAGE
//
//

#import "MageTabBarController.h"
#import "MeViewController.h"
#import "ObservationViewController.h"

@implementation MageTabBarController

- (void) prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    UINavigationController *navigationController = [self navigationController];
    [navigationController popToRootViewControllerAnimated:NO];
    
    if ([[segue identifier] isEqualToString:@"DisplayPersonFromMapSegue"]) {
        MeViewController *destination = (MeViewController *)[segue destinationViewController];
        [destination setUser:sender];
    } else if ([[segue identifier] isEqualToString:@"DisplayObservationFromMapSegue"]) {
        ObservationViewController *destination = (ObservationViewController *)[segue destinationViewController];
        [destination setObservation:sender];
    }
}

@end

//
//  MageInitialViewController.m
//  Mage
//
//

#import "MageInitialViewController.h"
#import "UserUtility.h"
#import "MageSessionManager.h"
#import "MageRootViewController.h"
#import "DeviceUUID.h"
#import "LocationService.h"
#import "Mage.h"
#import "Server.h"
#import "EventChooserController.h"
#import "StoredPassword.h"

@interface MageInitialViewController ()

@end

@implementation MageInitialViewController

- (void) viewDidAppear:(BOOL) animated {
    [super viewDidAppear:animated];
    
    [[Mage singleton] stopServices];
    
    // if the token is not expired skip the login module
    if ([[UserUtility singleton] isTokenExpired]) {
		[self performSegueWithIdentifier:@"DisplayLoginViewSegue" sender:nil];
        return;
    }

    [MageSessionManager manager].token = [StoredPassword retrieveStoredToken];
    
    [self performSegueWithIdentifier:@"DisplayEventViewSegue" sender:nil];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"DisplayEventViewSegue"]) {
        if ([Server currentEventId] != nil) {
            EventChooserController *destination = segue.destinationViewController;
            destination.passthrough = YES;
        }
    }
}

- (IBAction) unwindToInitial:(UIStoryboardSegue *) unwindSegue {
    [[UserUtility singleton] expireToken];
    [[Mage singleton] stopServices];
    [[LocationService singleton] stop];
}


@end

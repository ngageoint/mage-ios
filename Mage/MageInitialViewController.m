//
//  MageInitialViewController.m
//  Mage
//
//

#import "MageInitialViewController.h"
#import <UserUtility.h>
#import <HttpManager.h>
#import "MageRootViewController.h"
#import "DeviceUUID.h"
#import <LocationService.h>
#import <Mage.h>
#import <Server+helper.h>
#import "EventChooserController.h"

@interface MageInitialViewController ()

@end

@implementation MageInitialViewController

- (void) viewDidAppear:(BOOL) animated {
    [super viewDidAppear:animated];
    
    [[Mage singleton] stopServices];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // if the token is not expired skip the login module
    if ([[UserUtility singleton] isTokenExpired]) {
		[self performSegueWithIdentifier:@"DisplayLoginViewSegue" sender:nil];
        return;
    }
    NSString *token = [defaults valueForKeyPath:@"loginParameters.token"];
    [[HttpManager singleton].manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    [[HttpManager singleton].sessionManager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
    
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


@end

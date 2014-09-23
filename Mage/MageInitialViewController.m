//
//  MageInitialViewController.m
//  Mage
//
//  Created by Dan Barela on 7/15/14.
//

#import "MageInitialViewController.h"
#import <UserUtility.h>
#import <HttpManager.h>
#import "MageRootViewController.h"
#import "DisclaimerNavigationController.h"

@interface MageInitialViewController ()

@end

@implementation MageInitialViewController

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL) animated {
    [super viewDidAppear:animated];
    
    // stop the location fetch service
    [_locationFetchService stop];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    // if the token is not expired skip the login module
    if ([UserUtility isTokenExpired]) {
		[self performSegueWithIdentifier:@"DisplayDisclaimerViewSegue" sender:nil];
    } else {
        [[HttpManager singleton].manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", [defaults stringForKey:@"token"]] forHTTPHeaderField:@"Authorization"];
		[self performSegueWithIdentifier:@"DisplayRootViewSegue" sender:nil];
    }
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSString *segueIdentifier = [segue identifier];
    if ([segueIdentifier isEqualToString:@"DisplayDisclaimerViewSegue"]) {
        DisclaimerNavigationController *disclaimer = [segue destinationViewController];
		[disclaimer setManagedObjectContext:_managedObjectContext];
        [disclaimer setLocationFetchService:_locationFetchService];
        [disclaimer setObservationFetchService:_observationFetchService];
    } else if ([segueIdentifier isEqualToString:@"DisplayRootViewSegue"]) {
        MageRootViewController *rootView = [segue destinationViewController];
		[rootView setManagedObjectContext:_managedObjectContext];
        [rootView setLocationFetchService:_locationFetchService];
        [rootView setObservationFetchService:_observationFetchService];
    }
}

- (IBAction) unwindToInitial:(UIStoryboardSegue *) unwindSegue {
    [UserUtility expireToken];
}

@end

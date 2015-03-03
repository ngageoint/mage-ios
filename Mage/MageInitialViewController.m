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
#import "DeviceUUID.h"

#import <Mage.h>

@interface MageInitialViewController ()

@end

@implementation MageInitialViewController

- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) viewDidAppear:(BOOL) animated {
    [super viewDidAppear:animated];
    
    [[Mage singleton] stopServices];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // if the token is not expired skip the login module
    if ([[UserUtility singleton] isTokenExpired]) {
		[self performSegueWithIdentifier:@"DisplayDisclaimerViewSegue" sender:nil];
    } else {
        NSString *token = [defaults valueForKeyPath:@"loginParameters.token"];
        [[HttpManager singleton].manager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
        [[HttpManager singleton].sessionManager.requestSerializer setValue:[NSString stringWithFormat:@"Bearer %@", token] forHTTPHeaderField:@"Authorization"];
		[self performSegueWithIdentifier:@"DisplayRootViewSegue" sender:nil];
    }
}

- (IBAction) unwindToInitial:(UIStoryboardSegue *) unwindSegue {
    [[UserUtility singleton] expireToken];
    [[Mage singleton] stopServices];
}

@end

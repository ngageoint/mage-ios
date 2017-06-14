//
//  LoginViewController.m
//  MAGE
//
//  Created by William Newman on 11/4/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "LoginViewController.h"
#import "MageServer.h"
#import "Server.h"

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (weak, nonatomic) IBOutlet UIButton *serverURL;
@end

@implementation LoginViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    [self.versionLabel setText:[NSString stringWithFormat:@"v%@", versionString]];
    
    NSURL *url = [MageServer baseURL];
    if ([url absoluteString].length == 0) {
         [self performSegueWithIdentifier:@"setSeverURLSegue" sender:self];
    } else {
        [self.serverURL setTitle:[url absoluteString] forState:UIControlStateNormal];
    }
    
    // If the user is logging in, force them to pick the event again
    [Server removeCurrentEventId];
}
@end

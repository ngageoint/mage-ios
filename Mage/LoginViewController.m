//
//  LoginViewController.m
//  MAGE
//
//  Created by William Newman on 11/4/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "LoginViewController.h"
#import "MageServer.h"

@interface LoginViewController ()
@property (weak, nonatomic) IBOutlet UILabel *serverURL;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@end

@implementation LoginViewController

//  When the view reappears after logout we want to wipe the username and password fields
- (void)viewWillAppear:(BOOL)animated {
    
    NSString *versionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *buildString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    [self.versionLabel setText:[NSString stringWithFormat:@"v%@ b%@", versionString, buildString]];
    
    NSURL *url = [MageServer baseURL];
    [self.serverURL setText:[url absoluteString]];
}
@end

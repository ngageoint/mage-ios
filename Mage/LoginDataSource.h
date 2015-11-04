//
//  LoginDataSource.h
//  MAGE
//
//  Created by William Newman on 10/23/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MageServer.h"

@interface LoginDataSource : NSObject <UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) UITextField *usernameField;
@property (weak, nonatomic) UITextField *passwordField;
@property (weak, nonatomic) UISwitch *showPassword;
@property (weak, nonatomic) UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UITextView *loginStatus;

- (void) setAuthenticationWithServer: (MageServer *) server;

@end

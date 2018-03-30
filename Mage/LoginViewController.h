//
//  LoginViewController.h
//  MAGE
//
//  Created by William Newman on 11/4/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MageServer.h"
#import "User.h"

@protocol LoginDelegate <NSObject>

- (void) loginWithParameters: (NSDictionary *) parameters complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete;
- (void) changeServerURL;
- (void) createAccount;

@end

@interface LoginViewController : UIViewController

- (instancetype) initWithMageServer: (MageServer *) server andDelegate: (id<LoginDelegate>) delegate;
- (instancetype) initWithMageServer:(MageServer *)server andUser: (User *) user andDelegate:(id<LoginDelegate>)delegate;
- (void) authenticationHadFailure: (NSString *) errorString;

@end

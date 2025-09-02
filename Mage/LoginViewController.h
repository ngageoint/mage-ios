//
//  LoginViewController.h
//  MAGE
//
//  Created by William Newman on 11/4/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContactInfo.h"
#import "Authentication.h"
#import <MaterialComponents/MaterialContainerScheme.h>

@class User;
@class MageServer;

@protocol LoginDelegate

- (void) loginWithParameters: (NSDictionary *) parameters withAuthenticationStrategy: (NSString *) authenticationStrategy complete:(void (^) (AuthenticationStatus authenticationStatus, NSString *errorString)) complete;
- (void) changeServerURL;
- (void) createAccount;

@end

//@interface LoginViewController : UIViewController
//
//- (instancetype) initWithMageServer: (MageServer *) server andDelegate: (id<LoginDelegate>) delegate andScheme: (id<MDCContainerScheming>) containerScheme;
//- (instancetype) initWithMageServer:(MageServer *)server andUser: (User *) user andDelegate:(id<LoginDelegate>)delegate andScheme: (id<MDCContainerScheming>) containerScheme;
//
//- (void) setContactInfo: (ContactInfo *) contactInfo;
//
//@end

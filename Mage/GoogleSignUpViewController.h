//
//  GoogleSignUpViewController.h
//  MAGE
//
//  Created by Dan Barela on 9/14/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleSignIn/GoogleSignIn.h>
#import "MageServer.h"
#import "SignUpDelegate.h"

@interface GoogleSignUpViewController : UIViewController

- (instancetype) initWithServer: (MageServer *) server andGoogleUser: (GIDGoogleUser *) googleUser andDelegate: (id<SignUpDelegate>) delegate;

@end

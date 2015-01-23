//
//  LoginViewController.h
//  Mage
//
//  Created by Dan Barela on 2/19/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Authentication.h"

@interface LoginViewController : UIViewController<AuthenticationDelegate, UITextFieldDelegate>

@end

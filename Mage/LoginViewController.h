//
//  LoginViewController.h
//  Mage
//
//  Created by Dan Barela on 2/19/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Authentication.h"
#import "ManagedObjectContextHolder.h"

@interface LoginViewController : UIViewController<AuthenticationDelegate, UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet ManagedObjectContextHolder *contextHolder;

@end

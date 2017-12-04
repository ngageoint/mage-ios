//
//  ChangePasswordViewController.h
//  MAGE
//
//  Created by Dan Barela on 12/4/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ChangePasswordDelegate

- (void) changePasswordWithParameters: (NSDictionary *) parameters atURL: (NSURL *) url;
- (void) changePasswordCanceled;

@end

@interface ChangePasswordViewController : UIViewController

- (instancetype) initWithLoggedIn: (BOOL) loggedIn;

@end

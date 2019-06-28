//
//  LdapLoginView.h
//  MAGE
//
//  Created by William Newman on 6/18/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "LoginViewController.h"

@interface LdapLoginView : UIStackView

@property (strong, nonatomic) NSDictionary *strategy;
@property (strong, nonatomic) User *user;

@property (strong, nonatomic) id<LoginDelegate> delegate;

@end

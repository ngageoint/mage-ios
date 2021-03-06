//
//  LocalLoginView.h
//  MAGE
//
//  Created by Dan Barela on 4/12/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "User.h"
#import "LoginViewController.h"

@interface LocalLoginView : UIStackView

@property (strong, nonatomic) NSDictionary *strategy;
@property (strong, nonatomic) User *user;

@property (strong, nonatomic) id<LoginDelegate> delegate;

@end

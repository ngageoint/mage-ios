//
//  LocalAuthenticationTableViewCell.h
//  MAGE
//
//  Created by William Newman on 11/3/15.
//  Copyright © 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LocalAuthenticationTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UISwitch *showPassword;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@end

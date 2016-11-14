//
//  UserTableViewController.h
//  MAGE
//
//  Created by William Newman on 11/14/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "UserDataStore.h"

@interface UserTableViewController : UITableViewController
@property (strong, nonatomic) NSArray *userIds;
@property (strong, nonatomic) IBOutlet UserDataStore *userDataStore;
@end

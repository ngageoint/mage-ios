//
//  SettingsViewController.h
//  Mage
//
//  Created by Dan Barela on 2/21/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RESideMenu.h"
#import "ValuePickerTableViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "ManagedObjectContextHolder.h"

@interface SettingsViewController : UITableViewController<CLLocationManagerDelegate>

@property (strong, nonatomic) IBOutlet ManagedObjectContextHolder *contextHolder;

@end

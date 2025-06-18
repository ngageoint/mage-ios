//
//  SettingsCoordinator.m
//  MAGE
//
//  Created by William Newman on 2/19/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "SettingsCoordinator.h"
#import "SettingsTableViewController.h"

@interface SettingsCoordinator()

@property (strong, nonatomic) UISplitViewController *splitViewController;

@end

@implementation SettingsCoordinator

- (void) start {
    // create a uisplitviewcontroller
    self.splitViewController = [[UISplitViewController alloc] init];
    
    SettingsTableViewController *masterViewController = [[SettingsTableViewController alloc] initWithStyle:UITableViewStyleGrouped];
    UIViewController *detailViewController = [[UIViewController alloc] initWithNibName:@"SettingsDetailView" bundle:nil];
    self.splitViewController.viewControllers = [NSArray arrayWithObjects:masterViewController, detailViewController, nil];
}

@end

//
//  MainSettingsViewController.m
//  MAGE
//
//  Created by William Newman on 11/7/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "SettingsViewController.h"
#import "SettingsTableViewController.h"

@interface SettingsViewController ()<UISplitViewControllerDelegate>

@property (nonatomic, weak) UISplitViewController *splitViewController;
@property (nonatomic, assign) BOOL isCollapsed;

@end

@implementation SettingsViewController

-(void) viewDidLoad {
    [super viewDidLoad];
    
    self.splitViewController = (UISplitViewController *) [self.viewControllers firstObject];
    [self.splitViewController setPreferredDisplayMode:UISplitViewControllerDisplayModeAllVisible];
    self.splitViewController.delegate = self;
    
    if (self.dismissable) {
        UINavigationController *detailController = [self.splitViewController.viewControllers lastObject];
        detailController.topViewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(done:)];
    }
}

-(BOOL) splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
    
    return YES;
}

- (UIViewController *)primaryViewControllerForCollapsingSplitViewController:(UISplitViewController *)splitViewController {
    self.isCollapsed = YES;
    [self reloadSettingsTable];

    return nil;
}

- (UIViewController *)primaryViewControllerForExpandingSplitViewController:(UISplitViewController *)splitViewController {
    self.isCollapsed = NO;
    [self reloadSettingsTable];

    return nil;
}

- (void) reloadSettingsTable {
    UINavigationController *masterController = [self.splitViewController.viewControllers firstObject];
    SettingsTableViewController *settingsTableViewController = [masterController.viewControllers firstObject];
    settingsTableViewController.showDisclosureIndicator = self.isCollapsed;
    [settingsTableViewController.tableView reloadData];
}

-(void) done:(UIBarButtonItem *) sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end

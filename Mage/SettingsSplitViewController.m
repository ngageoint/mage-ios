//
//  SettingsSplitViewController.m
//  MAGE
//
//  Created by William Newman on 10/4/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "SettingsSplitViewController.h"
#import "SettingsTableViewController_iPad.h"

@interface SettingsSplitViewController () <UISplitViewControllerDelegate, SettingSelectionDelegate>
@property (nonatomic, strong) UIBarButtonItem *doneButton;
@property (nonatomic, strong) UIViewController *detailViewController;
@end

@implementation SettingsSplitViewController

-(void) viewDidLoad {
    self.delegate = self;
    
    UINavigationController *masterViewController = [self.viewControllers firstObject];
    SettingsTableViewController_iPad *viewController = (SettingsTableViewController_iPad *) [masterViewController topViewController];
    viewController.settingSelectionDelegate = self;
    
    UINavigationItem *navigationItem = [viewController navigationItem];
    UIBarButtonItem *doneButton = navigationItem.leftBarButtonItem;
    [doneButton setTarget:self];
    [doneButton setAction:@selector(dismissSettings:)];
    
    self.detailViewController = [self.viewControllers lastObject];
}

- (void) dismissSettings:(UIBarButtonItem *)sender {
    NSLog(@"Done");
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (BOOL)splitViewController:(UISplitViewController *)svc
   shouldHideViewController:(UIViewController *)vc
              inOrientation:(UIInterfaceOrientation)orientation {
    return NO;
}

-(void) selectedSetting:(NSString *) storyboardId {
    NSLog(@"Selected %@", storyboardId);
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
    UIViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:storyboardId];
    self.detailViewController = viewController;
    
    NSMutableArray* viewControllers = [self.viewControllers mutableCopy];
    [viewControllers replaceObjectAtIndex:1 withObject:viewController]; //index 1 corresponds to the detail VC
    self.viewControllers = viewControllers;
    
    
    //    UINavigationController *navController=[[UINavigationController alloc] init];
    //
    //    YourSplitViewAppDelegate *delegate=[[UIApplication sharedApplication] delegate];
    //
    //    NSArray *viewControllers=[[NSArray alloc] initWithObjects:[delegate.splitViewController.viewControllers objectAtIndex:0],navController,nil];
    //
    //    delegate.splitViewController.viewControllers = viewControllers;
    //
    //    [localdetailViewController release];
    //
    //    [navController release];
}


@end

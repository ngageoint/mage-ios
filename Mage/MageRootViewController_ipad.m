//
//  MageRootViewController_ipad.m
//  MAGE
//
//  Created by William Newman on 9/19/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MageRootViewController_ipad.h"

#import "MageSplitViewController.h"
#import <HttpManager.h>
#import "User+helper.h"

@interface MageRootViewController_ipad () <UISplitViewControllerDelegate>

@end

@implementation MageRootViewController_ipad

- (void) viewDidLoad {
    [self startServices];
    
    MageSplitViewController *splitViewController = [self.viewControllers firstObject];
    splitViewController.delegate = self;
    [splitViewController setManagedObjectContext:self.managedObjectContext];
    
    UINavigationController *detailViewController = [splitViewController.viewControllers lastObject];
    id detailNavigationController = detailViewController.topViewController;
//    detailViewController.topViewController.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem;

    [detailNavigationController setManagedObjectContext:self.managedObjectContext];
    
    UINavigationController *navigationViewController = [splitViewController.viewControllers firstObject];
    for (id viewController in navigationViewController.topViewController.childViewControllers) {
        if ([viewController respondsToSelector:@selector(setManagedObjectContext:)]) {
            [viewController setManagedObjectContext:self.managedObjectContext];
        }
    }
    
    [super viewDidLoad];
}

- (void) startServices {
    _locationService = [[LocationService alloc] initWithManagedObjectContext:self.managedObjectContext];
    [_locationService start];
    
    NSOperation *usersPullOp = [User operationToFetchUsersWithManagedObjectContext:self.managedObjectContext];
    NSOperation *startLocationFetchOp = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"done with intial user fetch, lets start the location fetch service");
        [_locationFetchService start];
    }];
    
    NSOperation *startObservationFetchOp = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"done with intial user fetch, lets start the observation fetch service");
        [_observationFetchService start];
    }];
    
    [startObservationFetchOp addDependency:usersPullOp];
    [startLocationFetchOp addDependency:usersPullOp];
    
    // Add the operations to the queue
    [[HttpManager singleton].manager.operationQueue addOperations:@[usersPullOp, startObservationFetchOp, startLocationFetchOp] waitUntilFinished:NO];
}

#pragma mark - Split view

- (BOOL)splitViewController:(UISplitViewController *)splitViewController collapseSecondaryViewController:(UIViewController *)secondaryViewController ontoPrimaryViewController:(UIViewController *)primaryViewController {
//    if ([secondaryViewController isKindOfClass:[UINavigationController class]] && [[(UINavigationController *)secondaryViewController topViewController] isKindOfClass:[DetailViewController class]] && ([(DetailViewController *)[(UINavigationController *)secondaryViewController topViewController] detailItem] == nil)) {
//        // Return YES to indicate that we have handled the collapse by doing nothing; the secondary controller will be discarded.
//        return YES;
//    } else {
//        return NO;
//    }
    return YES;
}

@end

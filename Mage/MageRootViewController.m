//
//  MageRootViewController.m
//  Mage
//
//  Created by Dan Barela on 4/28/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "MageRootViewController.h"
#import "MageNavigationController.h"
#import "MapViewController.h"
#import "MageNavigationMenuViewController.h"
#import <HttpManager.h>

#import "User+helper.h"
#import <Observation+helper.h>

#import <Location+helper.h>
#import <Layer+helper.h>
#import <Form.h>

@implementation MageRootViewController

- (void) viewDidLoad {
    [self startServices];
    
    UITabBarItem *mapTabBar = [[self.tabBar items] objectAtIndex:0];
    [mapTabBar setSelectedImage:[UIImage imageNamed:@"map_selected.png"]];
    
    UITabBarItem *observationsTabBar = [[self.tabBar items] objectAtIndex:1];
    [observationsTabBar setSelectedImage:[UIImage imageNamed:@"observations_selected.png"]];
    
    UITabBarItem *peopleTabBar = [[self.tabBar items] objectAtIndex:2];
    [peopleTabBar setSelectedImage:[UIImage imageNamed:@"people_selected.png"]];
    
    for (UINavigationController *navigationController in self.viewControllers) {
        id viewController = navigationController.topViewController;
        if ([viewController respondsToSelector:@selector(setManagedObjectContext:)]) {
            [viewController setManagedObjectContext:self.managedObjectContext];
        }
    }
	
	[super viewDidLoad];
}

- (void) startServices {
    _locationService = [[LocationService alloc] initWithManagedObjectContext:_managedObjectContext];
    [_locationService start];
    
    NSOperation *usersPullOp = [User operationToFetchUsersWithManagedObjectContext:_managedObjectContext];
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

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

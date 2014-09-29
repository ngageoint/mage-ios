//
//  MageSplitViewController.m
//  MAGE
//
//  Created by William Newman on 9/15/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MageSplitViewController.h"
#import "UserUtility.h"
#import "HttpManager.h"
#import "MapViewController.h"
#import "MageTabBarController.h"
#import "ObservationTableViewController.h"
#import "PeopleTableViewController.h"

@interface MageSplitViewController ()

@end

@implementation MageSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self startServices];
    
    UINavigationController *masterViewController = [self.viewControllers firstObject];
    UINavigationController *detailViewController = [self.viewControllers lastObject];
    
    MageTabBarController *tabBarController = (MageTabBarController *) [masterViewController topViewController];
    MapViewController *mapViewController = (MapViewController *) [detailViewController topViewController];
    
    ObservationTableViewController *observationTableViewController = (ObservationTableViewController *) [tabBarController.viewControllers objectAtIndex:0];
    observationTableViewController.observationDataStore.observationSelectionDelegate = mapViewController.mapDelegate;
    mapViewController.mapDelegate.mapObservationCalloutDelegate = tabBarController.observationCalloutDelegate;
    
    PeopleTableViewController *peopleTableViewController = (PeopleTableViewController *) [tabBarController.viewControllers objectAtIndex:1];
    peopleTableViewController.peopleDataStore.personSelectionDelegate = mapViewController.mapDelegate;
    mapViewController.mapDelegate.mapUserCalloutDelegate = tabBarController.userCalloutDelegate;

    UITabBarItem *observationsTabBar = [[[tabBarController tabBar] items] objectAtIndex:0];
    [observationsTabBar setSelectedImage:[UIImage imageNamed:@"observations_selected.png"]];
    
    UITabBarItem *peopleTabBar = [[[tabBarController tabBar] items] objectAtIndex:1];
    [peopleTabBar setSelectedImage:[UIImage imageNamed:@"people_selected.png"]];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) startServices {
    _locationService = [[LocationService alloc] initWithManagedObjectContext:self.contextHolder.managedObjectContext];
    [_locationService start];
    
    NSOperation *usersPullOp = [User operationToFetchUsersWithManagedObjectContext:self.contextHolder.managedObjectContext];
    NSOperation *startLocationFetchOp = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"done with intial user fetch, lets start the location fetch service");
        [self.fetchServicesHolder.locationFetchService start];
    }];
    
    NSOperation *startObservationFetchOp = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"done with intial user fetch, lets start the observation fetch service");
        [self.fetchServicesHolder.observationFetchService start];
    }];
    
    [startObservationFetchOp addDependency:usersPullOp];
    [startLocationFetchOp addDependency:usersPullOp];
    
    // Add the operations to the queue
    [[HttpManager singleton].manager.operationQueue addOperations:@[usersPullOp, startObservationFetchOp, startLocationFetchOp] waitUntilFinished:NO];
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end

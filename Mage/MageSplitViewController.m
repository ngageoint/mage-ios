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
#import "ObservationTableViewController.h"
#import "PeopleTableViewController.h"

@interface MageSplitViewController ()

@end

@implementation MageSplitViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // stop the location fetch service
//    [_locationFetchService stop];
    
    UINavigationController *masterViewController = [self.viewControllers firstObject];
    UINavigationController *detailViewController = [self.viewControllers lastObject];
    
    UITabBarController *tabBarController = (UITabBarController *) [masterViewController topViewController];
    MapViewController *mapViewController = (MapViewController *) [detailViewController topViewController];
    ObservationTableViewController *observationTableViewController = [tabBarController.viewControllers objectAtIndex:0];
    observationTableViewController.observationDataStore.observationSelectionDelegate = mapViewController;
    
    PeopleTableViewController *peopleTableViewController = [tabBarController.viewControllers objectAtIndex:1];

    UITabBarItem *observationsTabBar = [[[tabBarController tabBar] items] objectAtIndex:0];
    [observationsTabBar setSelectedImage:[UIImage imageNamed:@"observations_selected.png"]];
    
    UITabBarItem *peopleTabBar = [[[tabBarController tabBar] items] objectAtIndex:1];
    [peopleTabBar setSelectedImage:[UIImage imageNamed:@"people_selected.png"]];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}


@end

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
#import <LocationResource.h>
#import <UserResource.h>


#import <Location+helper.h>
#import <Layer+helper.h>
#import <Form.h>

@interface MageRootViewController ()

@end

@implementation MageRootViewController

- (void) viewDidLoad {
    [self initialFetch];
    
	self.menuPreferredStatusBarStyle = UIStatusBarStyleLightContent;
    self.contentViewShadowColor = [UIColor blackColor];
    self.contentViewShadowOffset = CGSizeMake(0, 0);
    self.contentViewShadowOpacity = 0.6;
    self.contentViewShadowRadius = 12;
    self.contentViewShadowEnabled = YES;
    
	MageNavigationController *mageNavigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"contentViewController"];
	MapViewController *mapViewController = [mageNavigationController.viewControllers objectAtIndex:0];
	mapViewController.managedObjectContext = _managedObjectContext;
    self.contentViewController = mageNavigationController;
	
	MageNavigationMenuViewController *leftMenuController = [self.storyboard instantiateViewControllerWithIdentifier:@"mageNavigationMenuViewController"];
	leftMenuController.managedObjectContext = _managedObjectContext;
    self.leftMenuViewController = leftMenuController;
	
    self.rightMenuViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"mageFilterMenuViewController"];
    
    NSArray *colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithRed:82.0/255.0 green:120.0/255.0 blue:162.0/255.0 alpha:1.0] CGColor], (id)[[UIColor colorWithRed:27.0/255.0 green:64.0/255.0 blue:105.0/25.0 alpha:1.0] CGColor], nil];
    CGPoint startPoint;
    startPoint.x = self.view.frame.size.width/2;
    startPoint.y = self.view.frame.size.height/2;
    CGGradientRef gradient;
    gradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), (CFArrayRef)colors, NULL);
    UIGraphicsBeginImageContext(self.view.bounds.size);
    CGContextDrawRadialGradient(UIGraphicsGetCurrentContext(), gradient, startPoint, 0, startPoint, 5000, 0);
    UIImage *gradientImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.backgroundImage = gradientImage;
    self.delegate = self;
	
	[super viewDidLoad];
}

- (void) initialFetch {
    HttpManager *http = [HttpManager singleton];
    
    NSOperation* layerOp = [Layer fetchFeatureLayersFromServerWithManagedObjectContext:_managedObjectContext];
    NSOperation* userOp = [UserResource operationToFetchUsersWithManagedObjectContext:_managedObjectContext];
	NSOperation* locationOp = [LocationResource operationToFetchLocationsWithManagedObjectContext:_managedObjectContext];
    [locationOp addDependency:userOp];
    [layerOp addDependency:userOp];
    
    [http.manager.operationQueue setSuspended:YES];
    
    // Add the operations to the queue
    
    [http.manager.operationQueue addOperation:layerOp];
    [http.manager.operationQueue addOperation:userOp];
    [http.manager.operationQueue addOperation:locationOp];
    
    [http.manager.operationQueue setSuspended:NO];
}

- (void)sideMenu:(RESideMenu *)sideMenu willShowMenuViewController:(UIViewController *)menuViewController
{
    NSLog(@"willShowMenuViewController: %@", NSStringFromClass([menuViewController class]));
}

- (void)sideMenu:(RESideMenu *)sideMenu didShowMenuViewController:(UIViewController *)menuViewController
{
    NSLog(@"didShowMenuViewController: %@", NSStringFromClass([menuViewController class]));
}

- (void)sideMenu:(RESideMenu *)sideMenu willHideMenuViewController:(UIViewController *)menuViewController
{
    NSLog(@"willHideMenuViewController: %@", NSStringFromClass([menuViewController class]));
}

- (void)sideMenu:(RESideMenu *)sideMenu didHideMenuViewController:(UIViewController *)menuViewController
{
    NSLog(@"didHideMenuViewController: %@", NSStringFromClass([menuViewController class]));
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

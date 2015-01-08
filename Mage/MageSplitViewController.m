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
#import "MapViewController_iPad.h"
#import "MageTabBarController.h"
#import "ObservationTableViewController.h"
#import "PeopleTableViewController.h"
#import "MapCalloutTappedSegueDelegate.h"
#import "ImageViewerViewController.h"

@interface MageSplitViewController () <MapCalloutTapped, AttachmentSelectionDelegate>
    @property(nonatomic, weak) MageTabBarController *tabBarController;
    @property(nonatomic, weak) MapViewController_iPad *mapViewController;
    @property(nonatomic, weak) UIBarButtonItem *masterViewButton;
    @property(nonatomic, weak) UIPopoverController *masterViewPopover;
    @property(nonatomic, strong) NSArray *mapCalloutDelegates;
@end

@implementation MageSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self startServices];
    
    self.delegate = self;
    
    UINavigationController *masterViewController = [self.viewControllers firstObject];
    self.mapViewController = [self.viewControllers lastObject];
    self.tabBarController = (MageTabBarController *) [masterViewController topViewController];
    
    self.mapViewController.mapDelegate.mapCalloutDelegate = self;
    
    ObservationTableViewController *observationTableViewController = (ObservationTableViewController *) [self.tabBarController.viewControllers objectAtIndex:0];
    observationTableViewController.observationDataStore.observationSelectionDelegate = self.mapViewController.mapDelegate;
    observationTableViewController.attachmentDelegate = self;
    
    PeopleTableViewController *peopleTableViewController = (PeopleTableViewController *) [self.tabBarController.viewControllers objectAtIndex:1];
    peopleTableViewController.peopleDataStore.personSelectionDelegate = self.mapViewController.mapDelegate;
    
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
        self.masterViewButton = self.displayModeButtonItem;
        [self ensureButtonVisible];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) startServices {
    [_locationServiceHolder.locationService start];
    
    NSOperation *usersPullOp = [User operationToFetchUsers];
    NSOperation *startLocationFetchOp = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"done with intial user fetch, lets start the location fetch service");
//        [self.fetchServicesHolder.locationFetchService start];
    }];
    
    NSOperation *startObservationFetchOp = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"done with intial user fetch, lets start the observation fetch service");
        [self.fetchServicesHolder.observationFetchService start];
    }];
    
    [startObservationFetchOp addDependency:usersPullOp];
    [startLocationFetchOp addDependency:usersPullOp];
    
    [self.fetchServicesHolder.observationPushService start];
    [self.fetchServicesHolder.attachmentPushService start];
    
    // Add the operations to the queue
    [[HttpManager singleton].manager.operationQueue addOperations:@[usersPullOp, startObservationFetchOp, startLocationFetchOp] waitUntilFinished:NO];
}

-(void) calloutTapped:(id) calloutItem {
    if ([calloutItem isKindOfClass:[User class]]) {
        [self.tabBarController.userMapCalloutTappedDelegate calloutTapped:calloutItem];
    } else if ([calloutItem isKindOfClass:[Observation class]]) {
        [self.tabBarController.observationMapCalloutTappedDelegate calloutTapped:calloutItem];
    }
    
    if (self.masterViewButton && self.masterViewPopover) {
        [self.masterViewPopover presentPopoverFromBarButtonItem:self.masterViewButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void) ensureButtonVisible {
    self.masterViewButton.title = @"List";
    self.masterViewButton.style = UIBarButtonItemStylePlain;
    
    NSMutableArray *items = [self.mapViewController.toolbar.items mutableCopy];
    if (!items) {
        items = [NSMutableArray arrayWithObject:self.masterViewButton];
    } else if ([items objectAtIndex:0] != self.masterViewButton) {
        [items insertObject:self.masterViewButton atIndex:0];
    }
    
    [self.mapViewController.toolbar setItems:items];
}

- (void)splitViewController:(UISplitViewController *)svc
    willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode {
    NSLog(@"change to display mode %d", displayMode);
    // never called in ios 7
    self.masterViewButton = svc.displayModeButtonItem;
    if (displayMode == UISplitViewControllerDisplayModePrimaryOverlay) {
        [self ensureButtonVisible];
    } else if (displayMode == UISplitViewControllerDisplayModePrimaryHidden) {
        [self ensureButtonVisible];
    } else if (displayMode == UISplitViewControllerDisplayModeAllVisible) {
        NSMutableArray *items = [self.mapViewController.toolbar.items mutableCopy];
        [items removeObject:self.masterViewButton];
        [self.mapViewController.toolbar setItems:items];
        
        self.masterViewButton = nil;
        self.masterViewPopover = nil;
    }
}

-(void)splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *) button {
    NSLog(@"will show view controller");
    // never called in ios 8
    self.masterViewButton = nil;
    self.masterViewPopover = nil;
    
    NSMutableArray *items = [self.mapViewController.toolbar.items mutableCopy];
    [items removeObject:button];
    [self.mapViewController.toolbar setItems:items];
}


-(void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)button forPopoverController:(UIPopoverController *) pc {
    NSLog(@"will hide view controller");
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
        return;
    }
    // always called in both ios8 and 7
    self.masterViewButton = button;
    self.masterViewPopover = pc;
    [self ensureButtonVisible];
}
- (void) prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    if ([[segue identifier] isEqualToString:@"viewImageSegue"]) {
        // Get reference to the destination view controller
        ImageViewerViewController *vc = [segue destinationViewController];
        [vc setAttachment:sender];
    }
}

- (void) selectedAttachment:(Attachment *)attachment {
    NSLog(@"attachment selected");
    [self performSegueWithIdentifier:@"viewImageSegue" sender:attachment];
}

@end

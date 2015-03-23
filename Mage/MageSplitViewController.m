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
#import <Mage.h>

@interface MageSplitViewController () <AttachmentSelectionDelegate, UserSelectionDelegate, ObservationSelectionDelegate>
    @property(nonatomic, weak) MageTabBarController *tabBarController;
    @property(nonatomic, weak) MapViewController_iPad *mapViewController;
    @property(nonatomic, weak) UIBarButtonItem *masterViewButton;
    @property(nonatomic, weak) UIPopoverController *masterViewPopover;
    @property(nonatomic, strong) NSArray *mapCalloutDelegates;
@end

@implementation MageSplitViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[Mage singleton] startServices];
    
    self.delegate = self;
    
    UINavigationController *detailViewController = [self.viewControllers lastObject];

    self.mapViewController = (MapViewController_iPad *)detailViewController.topViewController;
    self.tabBarController = (MageTabBarController *) [self.viewControllers firstObject];
    
    self.mapViewController.mapDelegate.mapCalloutDelegate = self.mapViewController;
    
    ObservationTableViewController *observationTableViewController = (ObservationTableViewController *) [self.tabBarController.viewControllers objectAtIndex:0];
    observationTableViewController.observationDataStore.observationSelectionDelegate = self;
    observationTableViewController.attachmentDelegate = self;
    
    PeopleTableViewController *peopleTableViewController = (PeopleTableViewController *) [self.tabBarController.viewControllers objectAtIndex:1];
    peopleTableViewController.peopleDataStore.personSelectionDelegate = self;
}

- (void) viewDidAppear:(BOOL)animated {
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
        self.masterViewButton = self.displayModeButtonItem;
    }
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if(orientation != UIInterfaceOrientationLandscapeLeft && orientation != UIInterfaceOrientationLandscapeRight) {
        [self ensureButtonVisible];
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)selectedUser:(User *) user {
    [self.mapViewController selectedUser:user];
}

- (void)selectedUser:(User *) user region:(MKCoordinateRegion) region {
    [self.mapViewController selectedUser:user region:region];
}

- (void)selectedObservation:(Observation *) observation {
    [self.mapViewController selectedObservation:observation];
}

- (void)selectedObservation:(Observation *) observation region:(MKCoordinateRegion) region {
    [self.mapViewController selectedObservation:observation region:region];
}

- (void)observationDetailSelected:(Observation *)observation {
    [[UIApplication sharedApplication] sendAction:self.masterViewButton.action to:self.masterViewButton.target from:nil forEvent:nil];
    [self.mapViewController observationDetailSelected:observation];
}

- (void)userDetailSelected:(User *)user {
    [[UIApplication sharedApplication] sendAction:self.masterViewButton.action to:self.masterViewButton.target from:nil forEvent:nil];
    [self.mapViewController userDetailSelected:user];
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
    NSLog(@"will change to display mode");
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
    self.masterViewButton = button;
    self.masterViewPopover = pc;
    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
        return;
    }
    
    // always called in both ios8 and 7
    [self ensureButtonVisible];
}

- (void) selectedAttachment:(Attachment *)attachment {
    NSLog(@"attachment selected");
    [self.mapViewController performSegueWithIdentifier:@"viewImageSegue" sender:attachment];
}

@end

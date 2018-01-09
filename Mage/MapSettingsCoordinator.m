//
//  MapSettingsCoordinator.m
//  MAGE
//
//  Created by Dan Barela on 1/3/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapSettingsCoordinator.h"
#import "MapSettings.h"
#import "StaticLayerTableViewController.h"
#import "OfflineMapTableViewController.h"
#import "UIColor+UIColor_Mage.h"

@interface MapSettingsCoordinator() <MapSettingsDelegate>

@property (strong, nonatomic) UINavigationController *rootViewController;
@property (strong, nonatomic) UINavigationController *settingsNavController;
@property (strong, nonatomic) UIView *sourceView;

@end

@implementation MapSettingsCoordinator

- (instancetype) initWithRootViewController: (UINavigationController *) rootViewController {
    self = [super init];
    self.rootViewController = rootViewController;
    return self;
}

- (instancetype) initWithRootViewController: (UINavigationController *) rootViewController andSourceView: (UIView *) sourceView {
    self = [super init];
    self.rootViewController = rootViewController;
    self.sourceView = sourceView;
    return self;
}

- (void) start {
    MapSettings *settings = [[MapSettings alloc] initWithDelegate: self];
    self.settingsNavController = [[UINavigationController alloc] initWithRootViewController:settings];
    
    self.settingsNavController.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *popoverPresentationController = self.settingsNavController.popoverPresentationController;
    popoverPresentationController.sourceView = self.sourceView;
    popoverPresentationController.sourceRect = CGRectMake(0, 0, self.sourceView.frame.size.width, self.sourceView.frame.size.height);
    popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
    popoverPresentationController.backgroundColor = [UIColor primaryColor];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(settingsComplete)];
    [settings.navigationItem setLeftBarButtonItem:doneButton];
    settings.title = @"Map Settings";
    
    [self.rootViewController presentViewController:self.settingsNavController animated:YES completion:nil];
}

- (void) settingsComplete {
    [self.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void) offlineMapsCellTapped {
    OfflineMapTableViewController *offlineMapController = [[OfflineMapTableViewController alloc] init];
    [self.settingsNavController pushViewController:offlineMapController animated:YES];
}

- (void) staticLayersCellTapped {
    StaticLayerTableViewController *staticController = [[StaticLayerTableViewController alloc] init];
    [self.settingsNavController pushViewController:staticController animated:YES];
}

@end

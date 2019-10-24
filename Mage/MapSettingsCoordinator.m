//
//  MapSettingsCoordinator.m
//  MAGE
//
//  Created by Dan Barela on 1/3/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapSettingsCoordinator.h"
#import "MapSettings.h"
#import "OfflineMapTableViewController.h"
#import "OnlineMapTableViewController.h"
#import "UIColor+Mage.h"
#import "Layer.h"
#import "Server.h"

@interface MapSettingsCoordinator() <MapSettingsDelegate, UINavigationControllerDelegate>

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
    self.settingsNavController.delegate = self;
    
    self.settingsNavController.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *popoverPresentationController = self.settingsNavController.popoverPresentationController;
    popoverPresentationController.sourceView = self.sourceView;
    popoverPresentationController.sourceRect = CGRectMake(0, -5, self.sourceView.frame.size.width, self.sourceView.frame.size.height);
    popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
    popoverPresentationController.backgroundColor = [UIColor primary];
    
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(settingsComplete)];
    [settings.navigationItem setLeftBarButtonItem:doneButton];
    settings.title = @"Map Settings";
    
    [self.rootViewController presentViewController:self.settingsNavController animated:YES completion:nil];
}

- (void) settingsComplete {
    [self.rootViewController dismissViewControllerAnimated:YES completion:nil];
    
    if (self.delegate) {
        [self.delegate mapSettingsComplete:self];
    }
}

- (void) offlineMapsCellTapped {
    OfflineMapTableViewController *offlineMapController = [[OfflineMapTableViewController alloc] init];
    [self.settingsNavController pushViewController:offlineMapController animated:YES];
}

- (void) onlineMapsCellTapped {
    OnlineMapTableViewController *onlineMapController = [[OnlineMapTableViewController alloc] init];
    [self.settingsNavController pushViewController:onlineMapController animated:YES];
}

- (void) navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([viewController isKindOfClass:[MapSettings class]]) {
        MapSettings *settings = (MapSettings *)viewController;
        
        NSUInteger count = [Layer MR_countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"eventId == %@ AND type == %@ AND (loaded == 0 || loaded == nil)", [Server currentEventId], @"GeoPackage"] inContext:[NSManagedObjectContext MR_defaultContext]];
        settings.mapsToDownloadCount = count;
    }
}

@end

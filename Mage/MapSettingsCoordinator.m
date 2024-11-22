//
//  MapSettingsCoordinator.m
//  MAGE
//
//  Created by Dan Barela on 1/3/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapSettingsCoordinator.h"
#import "MapSettings.h"
//#import "OfflineMapTableViewController.h"
#import "OnlineMapTableViewController.h"
#import "MAGE-Swift.h"

@interface MapSettingsCoordinator() <MapSettingsDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) UINavigationController *rootViewController;
@property (strong, nonatomic) UINavigationController *settingsNavController;
@property (strong, nonatomic) UIView *sourceView;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@property (strong, nonatomic) NSManagedObjectContext *context;

@end

@implementation MapSettingsCoordinator

- (instancetype) initWithRootViewController: (UINavigationController *) rootViewController scheme: (id<MDCContainerScheming>)  containerScheme context: (NSManagedObjectContext *) context {
    self = [super init];
    self.scheme = containerScheme;
    self.rootViewController = rootViewController;
    self.settingsNavController = self.rootViewController;
    self.context = context;
    return self;
}

- (instancetype) initWithRootViewController: (UINavigationController *) rootViewController andSourceView: (UIView *) sourceView scheme: (id<MDCContainerScheming>) containerScheme context: (NSManagedObjectContext *) context {
    self = [super init];
    self.scheme = containerScheme;
    self.rootViewController = rootViewController;
    self.sourceView = sourceView;
    self.context = context;
    return self;
}

- (void) start {
    MapSettings *settings = [[MapSettings alloc] initWithDelegate: self scheme: self.scheme];
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(settingsComplete)];
    [settings.navigationItem setLeftBarButtonItem:doneButton];
    settings.title = @"Map Settings";
    
    if (self.sourceView) {
        self.settingsNavController = [[UINavigationController alloc] initWithRootViewController:settings];
        self.settingsNavController.delegate = self;
        
        self.settingsNavController.modalPresentationStyle = UIModalPresentationFullScreen;
        UIPopoverPresentationController *popoverPresentationController = self.settingsNavController.popoverPresentationController;
        popoverPresentationController.sourceView = self.sourceView;
        popoverPresentationController.sourceRect = CGRectMake(0, -5, self.sourceView.frame.size.width, self.sourceView.frame.size.height);
        popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
        popoverPresentationController.backgroundColor = self.scheme.colorScheme.backgroundColor;
        
        [self.rootViewController presentViewController:self.settingsNavController animated:YES completion:nil];
    } else {
        [self.rootViewController pushViewController:settings animated:true];
    }
}

- (void) settingsComplete {
    if (self.sourceView) {
        [self.rootViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.rootViewController popViewControllerAnimated:true];
    }
    
    if (self.delegate) {
        [self.delegate mapSettingsComplete:self];
    }
}

- (void) offlineMapsCellTapped {
    OfflineMapTableViewController *offlineMapController = [[OfflineMapTableViewController alloc] initWithScheme: self.scheme context:self.context];
    [self.settingsNavController pushViewController:offlineMapController animated:YES];
}

- (void) onlineMapsCellTapped {
    OnlineMapTableViewController *onlineMapController = [[OnlineMapTableViewController alloc] initWithScheme: self.scheme];
    [self.settingsNavController pushViewController:onlineMapController animated:YES];
}

- (void) navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if ([viewController isKindOfClass:[MapSettings class]]) {
        MapSettings *settings = (MapSettings *)viewController;
        
        NSUInteger count = [Layer MR_countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"eventId == %@ AND type == %@ AND (loaded == 0 || loaded == nil)", [Server currentEventId], @"GeoPackage"] inContext:self.context];
        settings.mapsToDownloadCount = count;
    }
}

@end

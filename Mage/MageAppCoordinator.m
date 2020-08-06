//
//  MageAppCoordinator.m
//  MAGE
//
//  Created by Dan Barela on 9/5/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MageAppCoordinator.h"

#import "AuthenticationCoordinator.h"
#import "EventChooserCoordinator.h"
#import "Event.h"

#import <UserNotifications/UserNotifications.h>
#import "UserUtility.h"
#import "MageSessionManager.h"
#import "StoredPassword.h"
#import "MageServer.h"
#import "MageSplitViewController.h"
#import "MAGE-Swift.h"

@interface MageAppCoordinator() <UNUserNotificationCenterDelegate, AuthenticationDelegate, EventChooserDelegate>

@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) NSMutableArray *childCoordinators;
@property (strong, nonatomic) ImageCacheProvider *imageCacheProvider;

@end

@implementation MageAppCoordinator

- (instancetype) initWithNavigationController: (UINavigationController *) navigationController forApplication: (UIApplication *) application {
    self = [super init];
    if (!self) return nil;
    
    _childCoordinators = [[NSMutableArray alloc] init];
    _navigationController = navigationController;

    [self setupPushNotificationsForApplication:application];
    self.imageCacheProvider = ImageCacheProvider.shared;
    
    return self;
}

- (void) start {
    // check for a valid token
    if ([[UserUtility singleton] isTokenExpired]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults removeObjectForKey:@"loginType"];
        [defaults synchronize];
        // start the authentication coordinator
        AuthenticationCoordinator *authCoordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:self.navigationController andDelegate:self];
        [_childCoordinators addObject:authCoordinator];
        [authCoordinator start];
    } else {
        [MageSessionManager sharedManager].token = [StoredPassword retrieveStoredToken];
        [self startEventChooser];
    }
}

- (void) authenticationSuccessful {
    [_childCoordinators removeLastObject];
    [self startEventChooser];
}

- (void) couldNotAuthenticate {
    // TODO figure out what to do here
}

- (void) startEventChooser {
    EventChooserCoordinator *eventChooser = [[EventChooserCoordinator alloc] initWithViewController:self.navigationController andDelegate:self];
    [_childCoordinators addObject:eventChooser];
    [eventChooser start];
}

- (void) eventChoosen:(Event *)event {
    [_childCoordinators removeLastObject];
    [Event sendRecentEvent];
    [FeedService.shared restart];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        MageSplitViewController *svc = [[MageSplitViewController alloc] init];
        svc.modalPresentationStyle = UIModalPresentationFullScreen;
        svc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self.navigationController presentViewController:svc animated:YES completion:NULL];
    } else if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        MageRootViewController *vc = [[MageRootViewController alloc] init];
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self.navigationController presentViewController:vc animated:NO completion:^{
            NSLog(@"presented iphone storyboard");
        }];
    }
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler {
    completionHandler(UNAuthorizationOptionAlert + UNAuthorizationOptionSound);
}

- (void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)(void))completionHandler {
    
}

- (void) setupPushNotificationsForApplication: (UIApplication *) application {
    UNNotificationAction *viewAction = [UNNotificationAction actionWithIdentifier:@"View"
                                                                            title:@"View" options:UNNotificationActionOptionNone];
    UNNotificationCategory *observationPulledCategory = [UNNotificationCategory categoryWithIdentifier:@"ObservationPulled"
                                                                                               actions:@[viewAction] intentIdentifiers:@[]
                                                                                               options:UNNotificationCategoryOptionNone];
    UNNotificationCategory *tokenExpiredCategory = [UNNotificationCategory categoryWithIdentifier:@"TokenExpired"
                                                                                          actions:@[viewAction] intentIdentifiers:@[]
                                                                                          options:UNNotificationCategoryOptionNone];
    NSSet *categories = [NSSet setWithObjects:observationPulledCategory, tokenExpiredCategory, nil];
    
    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    [center setNotificationCategories:categories];
    [center setDelegate:self];
    
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge + UNAuthorizationOptionAlert + UNAuthorizationOptionSound) completionHandler:^(BOOL granted, NSError * _Nullable error) {
    }];
}

@end

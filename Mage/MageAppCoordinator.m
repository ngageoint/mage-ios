//
//  MageAppCoordinator.m
//  MAGE
//
//  Created by Dan Barela on 9/5/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MageAppCoordinator.h"

#import "AuthenticationCoordinator.h"
#import "AuthenticationCoordinator_Server5.h"
#import "ServerURLController.h"
#import "EventChooserCoordinator.h"
#import "Event.h"

#import <UserNotifications/UserNotifications.h>
#import "UserUtility.h"
#import "MageSessionManager.h"
#import "StoredPassword.h"
#import "MageServer.h"
#import "MAGE-Swift.h"
#import "MagicalRecord+MAGE.h"

@interface MageAppCoordinator() <UNUserNotificationCenterDelegate, AuthenticationDelegate, EventChooserDelegate, ServerURLDelegate>

@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) NSMutableArray *childCoordinators;
@property (strong, nonatomic) ImageCacheProvider *imageCacheProvider;
@property (strong, nonatomic) ServerURLController *urlController;

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
        NSURL *url = [MageServer baseURL];
        if ([url absoluteString].length == 0) {
            [self changeServerUrl];
            return;
        } else {
            __weak __typeof__(self) weakSelf = self;
            [MageServer serverWithURL:url success:^(MageServer *mageServer) {
                [weakSelf startAuthentication:mageServer];
            } failure:^(NSError *error) {
                [weakSelf setServerURLWithError: error.localizedDescription];
            }];
        }
    } else {
        [MageSessionManager manager].token = [StoredPassword retrieveStoredToken];
        [self startEventChooser];
    }
}

- (void) startAuthentication:(MageServer *) mageServer {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"loginType"];
    [defaults synchronize];
    AuthenticationCoordinator *authCoordinator;
    if ([MageServer isServerVersion5]) {
        authCoordinator = [[AuthenticationCoordinator_Server5 alloc] initWithNavigationController:self.navigationController andDelegate:self];
    } else {
        authCoordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:self.navigationController andDelegate:self];
    }
    
    [_childCoordinators addObject:authCoordinator];
    [authCoordinator start:mageServer];
}

- (void) authenticationSuccessful {
    [_childCoordinators removeLastObject];
    [self startEventChooser];
}

- (void) couldNotAuthenticate {
    // TODO figure out what to do here
}

- (void) changeServerUrl {
    [self.navigationController popToRootViewControllerAnimated:NO];
    self.urlController = [[ServerURLController alloc] initWithDelegate:self];
    [FadeTransitionSegue addFadeTransitionToView:self.navigationController.view];
    [self.navigationController pushViewController:self.urlController animated:NO];
}

- (void) setServerURLWithError: (NSString *) error {
    self.urlController = [[ServerURLController alloc] initWithDelegate:self andError: error];
    [FadeTransitionSegue addFadeTransitionToView:self.navigationController.view];
    [self.navigationController pushViewController:self.urlController animated:NO];
}

- (void) setServerURL:(NSURL *) url {
    __weak __typeof__(self) weakSelf = self;
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"baseServerUrl"];
    [MageServer serverWithURL:url success:^(MageServer *mageServer) {
        [MagicalRecord deleteAndSetupMageCoreDataStack];
        dispatch_async(dispatch_get_main_queue(), ^{
            [FadeTransitionSegue addFadeTransitionToView:weakSelf.navigationController.view];
            [weakSelf.navigationController popViewControllerAnimated:NO];
            [weakSelf startAuthentication:mageServer];
        });
    } failure:^(NSError *error) {
        [weakSelf.urlController showError:error.localizedDescription];
    }];
}

- (void) cancelSetServerURL {
    [FadeTransitionSegue addFadeTransitionToView:self.navigationController.view];
    [self.navigationController popViewControllerAnimated:NO];
}


- (void) startEventChooser {
    EventChooserCoordinator *eventChooser = [[EventChooserCoordinator alloc] initWithViewController:self.navigationController andDelegate:self];
    [_childCoordinators addObject:eventChooser];
    [eventChooser start];
}

- (void) eventChoosen:(Event *)event {
    [_childCoordinators removeLastObject];
    [Event sendRecentEvent];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UIStoryboard *ipadStoryboard = [UIStoryboard storyboardWithName:@"Main_iPad" bundle:nil];
        UIViewController *vc = [ipadStoryboard instantiateInitialViewController];
        vc.modalPresentationStyle = UIModalPresentationFullScreen;
        vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self.navigationController presentViewController:vc animated:YES completion:NULL];
    } else if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        UIStoryboard *iphoneStoryboard = [UIStoryboard storyboardWithName:@"Main_iPhone" bundle:nil];
        UIViewController *vc = [iphoneStoryboard instantiateInitialViewController];
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

//
//  MageAppCoordinator.m
//  MAGE
//
//  Created by Dan Barela on 9/5/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MageAppCoordinator.h"

@import Authentication;
#import <Authentication/Authentication-Swift.h>

#import <UserNotifications/UserNotifications.h>
#import "MageSessionManager.h"
#import "StoredPassword.h"
#import "MAGE-Swift.h"
#import "MagicalRecord+MAGE.h"

@interface MageAppCoordinator() <UNUserNotificationCenterDelegate, AuthenticationDelegate, EventChooserDelegate, ServerURLDelegate>

@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) NSMutableArray *childCoordinators;
@property (strong, nonatomic) ImageCacheProvider *imageCacheProvider;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@property (strong, nonatomic) ServerURLController *urlController;
@property (strong, nonatomic) AuthenticationCoordinator *authCoordinator;
@property (strong, nonatomic) NSManagedObjectContext *context;
@end

@implementation MageAppCoordinator

- (instancetype) initWithNavigationController: (UINavigationController *) navigationController forApplication: (UIApplication *) application andScheme:(id<MDCContainerScheming>) containerScheme context: (NSManagedObjectContext *) context {
    self = [super init];
    if (!self) return nil;
    
    _childCoordinators = [[NSMutableArray alloc] init];
    _navigationController = navigationController;
    _scheme = containerScheme;
    _context = context;

    [self setupPushNotificationsForApplication:application];
    self.imageCacheProvider = ImageCacheProvider.shared;
    
    return self;
}

- (void) start {
    // check for a valid token
    if ([[UserUtility singleton] isTokenExpired]) {
        NSURL *url = [MageServer baseURL];
        if ([url absoluteString].length == 0) {
            [self changeServerURL];
            return;
        } else {
            __weak __typeof__(self) weakSelf = self;
            [MageServer serverWithUrl:url success:^(MageServer *mageServer) {
                [weakSelf startAuthentication:mageServer];
            } failure:^(NSError *error) {
                [weakSelf setServerURLWithError: error.localizedDescription];
            }];
        }
    } else {
        [MageSessionManager sharedManager].token = [StoredPassword retrieveStoredToken];
        [self startEventChooser];
    }
}

- (void) startAuthentication:(MageServer *) mageServer {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObjectForKey:@"loginType"];
    [defaults synchronize];
    if (self.authCoordinator != nil) {
        [_childCoordinators removeObject:self.authCoordinator];
        self.authCoordinator = nil;
    }

    self.authCoordinator = [[AuthenticationCoordinator alloc] initWithNavigationController:self.navigationController andDelegate:self andScheme:_scheme context: self.context];
    
    [_childCoordinators addObject:self.authCoordinator];
    [self.authCoordinator start:mageServer];
    [FeedService.shared stop];
}

- (void) authenticationSuccessful {
    [MageSessionManager sharedManager].token = [StoredPassword retrieveStoredToken];
    [_childCoordinators removeLastObject];
    [self startEventChooser];
}

- (void) couldNotAuthenticate {
    // TODO figure out what to do here
}

- (void) changeServerURL {
    [self.navigationController popToRootViewControllerAnimated:NO];
    self.urlController = [[ServerURLController alloc] initWithDelegate:self error:nil scheme:self.scheme];
    [FadeTransitionSegue addFadeTransitionToView:self.navigationController.view];
    [self.navigationController pushViewController:self.urlController animated:NO];
}

- (void) setServerURLWithError: (NSString *) error {
    self.urlController = [[ServerURLController alloc] initWithDelegate:self error:error scheme:self.scheme];
    [FadeTransitionSegue addFadeTransitionToView:self.navigationController.view];
    [self.navigationController pushViewController:self.urlController animated:NO];
}

- (void) setServerURLWithUrl:(NSURL *)url {
    __weak __typeof__(self) weakSelf = self;
    
    [[UserUtility singleton] expireToken]; // Clear any previous authentication methods when switching servers
    
    [MageServer serverWithUrl:url success:^(MageServer *mageServer) {
        [MageInitializer clearServerSpecificData];
        dispatch_async(dispatch_get_main_queue(), ^{
            [FadeTransitionSegue addFadeTransitionToView:weakSelf.navigationController.view];
            [weakSelf.navigationController popViewControllerAnimated:NO];
            [weakSelf startAuthentication:mageServer];
        });
    } failure:^(NSError *error) {
        [weakSelf.urlController showErrorWithError:error.localizedDescription userInfo:error.userInfo];
    }];
}

- (void) cancelSetServerURL {
    [FadeTransitionSegue addFadeTransitionToView:self.navigationController.view];
    [self.navigationController popViewControllerAnimated:NO];
    NSURL *url = [MageServer baseURL];
    if ([url absoluteString].length == 0) {
        [self changeServerURL];
        return;
    } else {
        __weak __typeof__(self) weakSelf = self;
        [MageServer serverWithUrl:url success:^(MageServer *mageServer) {
            [weakSelf startAuthentication:mageServer];
        } failure:^(NSError *error) {
            [weakSelf setServerURLWithError: error.localizedDescription];
        }];
    }
}


- (void) startEventChooser {
    [EventBridge fetchEvents];
    
    EventChooserCoordinator *eventChooser = [[EventChooserCoordinator alloc] initWithViewController:self.navigationController delegate:self scheme:_scheme];
    [_childCoordinators addObject:eventChooser];
    [eventChooser start];
}

- (void) eventChosenWithEvent:(Event *)event {
    [_childCoordinators removeLastObject];
    [Event sendRecentEvent];
    [FeedService.shared restart];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        MageSplitViewController *svc = [[MageSplitViewController alloc] initWithContainerScheme:self.scheme];
        svc.modalPresentationStyle = UIModalPresentationFullScreen;
        svc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        [self.navigationController presentViewController:svc animated:YES completion:NULL];
    } else if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        MageRootViewController *vc = [[MageRootViewController alloc] initWithContainerScheme:_scheme];
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

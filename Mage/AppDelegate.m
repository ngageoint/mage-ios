//
//  AppDelegate.m
//  Mage
//
//

#import "AppDelegate.h"
#import <CoreLocation/CoreLocation.h>
#import <UserNotifications/UserNotifications.h>
#import "UIImage+Thumbnail.h"
#import "LoginViewController.h"
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import "MageSessionManager.h"
#import "MagicalRecord+MAGE.h"
#import "GPKGGeoPackageFactory.h"
#import "MageConstants.h"
#import "MageOfflineObservationManager.h"
#import "MageAppCoordinator.h"
#import "TransitionViewController.h"
#import "MageConstants.h"
#import "MAGE-Swift.h"
#import "GeoPackageImporter.h"

@interface AppDelegate () <UNUserNotificationCenterDelegate>
@property (nonatomic, strong) TransitionViewController *splashView;
@property (nonatomic, strong) NSManagedObjectContext *pushManagedObjectContext;
@property (nonatomic, strong) MageAppCoordinator *appCoordinator;
@property (nonatomic, strong) UINavigationController *rootViewController;
@property (nonatomic, strong) UIApplication *application;
@property (nonatomic) BOOL applicationStarted;
@property (nonatomic, strong) GeoPackageImporter *gpImporter;
@property (nonatomic, strong) BaseMapOverlay *backgroundOverlay;
@property (nonatomic, strong) BaseMapOverlay *darkBackgroundOverlay;
@property (nonatomic, strong) GPKGGeoPackage *backgroundGeoPackage;
@property (nonatomic, strong) GPKGGeoPackage *darkBackgroundGeoPackage;
@end

@implementation AppDelegate

- (void) applicationProtectedDataDidBecomeAvailable:(UIApplication *)application {
    NSLog(@"Application Protected Data Did Become Available");
    if (!_applicationStarted) {
        _applicationStarted = YES;
        if(self.splashView != nil) {
            [self.splashView.view removeFromSuperview];
            self.splashView = nil;
        }
        [self setupMageApplication:application];
        [self startMageApp];
    }
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL protectedDataAvailable = _applicationStarted = [application isProtectedDataAvailable];

    self.window = [[UIWindow alloc] initWithFrame: [UIScreen mainScreen].bounds];
    [self.window makeKeyAndVisible];
    self.window.backgroundColor = [UIColor blackColor];
    self.window.overrideUserInterfaceStyle = [[NSUserDefaults standardUserDefaults] integerForKey:@"themeOverride"];
    
    [self createLoadingView];
    
    NSLog(@"Finish Launching Protected data is available? %d", protectedDataAvailable);
    
    if (protectedDataAvailable) {
        [self setupMageApplication:application];
        [self startMageApp];
    }

	return YES;
}

- (void) setupMageApplication: (UIApplication *) application {
    if (self.gpImporter == nil) {
        self.gpImporter = [[GeoPackageImporter alloc] init];
    }
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenDidExpire:) name: MAGETokenExpiredNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(geoPackageDownloaded:) name:Layer.GeoPackageDownloaded object:nil];
    
    [MageInitializer initializePreferences];
    [MageInitializer setupCoreData];
}

- (void) geoPackageDownloaded: (NSNotification *) notification {
    NSString *filePath = [notification.userInfo valueForKey:@"filePath"];
    [self.gpImporter importGeoPackageFileAsLink:filePath andMove:NO withLayerId:[notification.userInfo valueForKey:@"layerId"]];
}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary *)options {
    
    if (!url) {
        return NO;
    }
    
    NSLog(@"Application Open URL %@", url);
    if (url.isFileURL) {
        NSString * filePath = [url path];
        
        // Handle GeoPackage files
        [self.gpImporter handleGeoPackageImport:filePath];
    } else if ([[url scheme] isEqualToString:@"mage"] && [[url host] isEqualToString:@"app"]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MageAppLink" object:url];
    }
    
    
    return YES;
}

+ (UIViewController*) topMostController
{
    UIViewController *topController = [UIApplication sharedApplication].windows.firstObject.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

- (void) createLoadingView {
    [MAGEScheme setupApplicationAppearanceWithScheme:[MAGEScheme scheme]];
    self.rootViewController = [[UINavigationController alloc] init];
    self.rootViewController.navigationBarHidden = YES;
    [self.window setRootViewController:self.rootViewController];
    TransitionViewController *transitionView = [[TransitionViewController alloc] initWithNibName:@"TransitionScreen" bundle:nil];
    [transitionView applyThemeWithContainerScheme:[MAGEScheme scheme]];
    transitionView.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.rootViewController pushViewController:transitionView animated:NO];
}

- (void) startMageApp {
    __weak typeof(self) weakSelf = self;

    // do a canary save
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
        Canary *canary = [Canary MR_findFirstInContext:localContext];
        if (!canary) {
            canary = [Canary MR_createEntityInContext:localContext];
        }
        canary.launchDate = [NSDate date];
        NSLog(@"startMageApp Canary launch date %@", canary.launchDate);
    } completion:^(BOOL contextDidSave, NSError * _Nullable error) {
        NSLog(@"startMageApp canary save success? %d with error %@", contextDidSave, error);
        // error should be null and contextDidSave should be true
        if (contextDidSave && error == NULL) {
            self.appCoordinator = [[MageAppCoordinator alloc] initWithNavigationController:self.rootViewController forApplication:self.application andScheme:[MAGEScheme scheme]];
            [self.appCoordinator start];
            [self.gpImporter processOfflineMapArchives];
        } else {
            NSLog(@"Could not read or write from the database %@", error);
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Device Problem"
                                                                           message:[NSString stringWithFormat:@"An error has occurred on your device that is preventing MAGE from operating correctly. %@", error.localizedDescription]
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            
            [self.rootViewController presentViewController:alert animated:YES completion:nil];
            [MagicalRecord cleanUp];
            weakSelf.applicationStarted = NO;
        }
    }];
}

- (void) createRootView {
    [self createLoadingView];
    [self startMageApp];
}

- (void) chooseEvent {
    [Server removeCurrentEventId];
    [self.window.rootViewController dismissViewControllerAnimated:YES completion:^{
        [self createRootView];
    }];
}

- (void) logout {
    [self.backgroundGeoPackage close];
    [self.darkBackgroundGeoPackage close];
    self.backgroundGeoPackage = nil;
    self.darkBackgroundGeoPackage = nil;
    [self.backgroundOverlay cleanup];
    self.backgroundOverlay = nil;
    [self.darkBackgroundOverlay cleanup];
    self.darkBackgroundOverlay = nil;
    [[CacheOverlays getInstance] removeByCacheName:@"countries"];
    [[CacheOverlays getInstance] removeByCacheName:@"countries_dark"];
    [[Mage singleton] stopServices];
    [[LocationService singleton] stop];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [[UserUtility singleton] logoutWithCompletion:^{
        [defaults removeObjectForKey:@"loginType"];
        [defaults synchronize];
        [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
        [self createRootView];
    }];
}

- (void) applicationDidEnterBackground:(UIApplication *) application {
    NSLog(@"applicationDidEnterBackground");

    self.splashView = [[TransitionViewController alloc] initWithNibName:@"TransitionScreen" bundle:nil];
    [self.splashView applyThemeWithContainerScheme:[MAGEScheme scheme]];
    self.splashView.view.frame = [self.window frame];
    [self.window addSubview:self.splashView.view];
    
    [[Mage singleton] stopServices];
}

- (void) applicationWillResignActive:(UIApplication *)application {
    application.applicationIconBadgeNumber = [MageOfflineObservationManager offlineObservationCount];
}

- (void) applicationWillEnterForeground:(UIApplication *) application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"applicationWillEnterForeground");
    if (![[UserUtility singleton] isTokenExpired]) {
        [[Mage singleton] startServicesWithInitial:NO];
    }
}

- (void) applicationDidBecomeActive:(UIApplication *) application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSLog(@"applicationDidBecomeActive");
    if (_applicationStarted) {
        NSLog(@"Already checking if DB can be saved to");
        // the app was already started and is checking if it can save to the database, do not check again
        if(self.splashView != nil) {
            [self.splashView.view removeFromSuperview];
            self.splashView = nil;
        }
        return;
    }
    
    BOOL protectedDataAvailable = _applicationStarted = [application isProtectedDataAvailable];
    
    NSLog(@"Did Become Active Protected data is available? %d", protectedDataAvailable);
    
    if (protectedDataAvailable) {
        // do a canary save
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
            Canary *canary = [Canary MR_findFirstInContext:localContext];
            if (!canary) {
                canary = [Canary MR_createEntityInContext:localContext];
            }
            canary.launchDate = [NSDate date];
            NSLog(@"applicationDidBecomeActive Canary launch date %@", canary.launchDate);
        } completion:^(BOOL contextDidSave, NSError * _Nullable error) {
            NSLog(@"applicationDidBecomeActive canary save success? %d with error %@", contextDidSave, error);
            // error should be null and contextDidSave should be true
            if (error == NULL) {
                if(self.splashView != nil) {
                    [self.splashView.view removeFromSuperview];
                    self.splashView = nil;
                }
                
                [self.gpImporter processOfflineMapArchives];
            } else {
                NSLog(@"Could not read or write from the database %@", error);
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Device Problem"
                                                                               message:[NSString stringWithFormat:@"An error has occurred on your device that is preventing MAGE from operating correctly. %@", error.localizedDescription]
                                                                        preferredStyle:UIAlertControllerStyleAlert];
                
                [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
                
                [self.rootViewController presentViewController:alert animated:YES completion:nil];
            }
        }];
    }
    
}

- (void) application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler {
    // Handle attachments uploaded in the background
    if ([identifier isEqualToString:kAttachmentBackgroundSessionIdentifier]) {
        NSLog(@"ATTACHMENT - AppDelegate handleEventsForBackgroundURLSession");
        AttachmentPushService *service = [AttachmentPushService singleton];
        service.backgroundSessionCompletionHandler = completionHandler;
    }
}

- (BaseMapOverlay *) getBaseMap {
    if (self.backgroundOverlay != nil) {
        return self.backgroundOverlay;
    }
    
    // Add the GeoPackage caches
    GPKGGeoPackageManager * manager = [GPKGGeoPackageFactory manager];
    NSString *countriesGeoPackagePath = [[NSBundle mainBundle] pathForResource:@"countries" ofType:@"gpkg"];
    NSLog(@"Countries GeoPackage path %@", countriesGeoPackagePath);
    
    if (![manager exists:@"countries"]) {
        @try {
            [manager importGeoPackageFromPath:countriesGeoPackagePath];
        }
        @catch (NSException *e) {
            // probably was already imported and that is fine
        }
    }
    
    self.backgroundGeoPackage = [manager open:@"countries"];
    if (self.backgroundGeoPackage) {
        @try {
            GPKGFeatureDao * featureDao = [self.backgroundGeoPackage featureDaoWithTableName:@"countries"];
            
            // If indexed, add as a tile overlay
            GPKGFeatureTiles * featureTiles = [[GPKGFeatureTiles alloc] initWithGeoPackage:self.backgroundGeoPackage andFeatureDao:featureDao];
            [featureTiles setIndexManager:[[GPKGFeatureIndexManager alloc] initWithGeoPackage:self.backgroundGeoPackage andFeatureDao:featureDao]];
            
            self.backgroundOverlay = [[BaseMapOverlay alloc] initWithFeatureTiles:featureTiles];
            [self.backgroundOverlay setMinZoom:0];
            self.backgroundOverlay.darkTheme = NO;
            
            self.backgroundOverlay.canReplaceMapContent = true;
        }
        @catch (NSException *e) {
            NSLog(@"Exception initializing the base map GP %@", e);
        }
    }
    
    return self.backgroundOverlay;
}

- (BaseMapOverlay *) getDarkBaseMap {
    if (self.darkBackgroundOverlay != nil) {
        return self.darkBackgroundOverlay;
    }
    
    NSString *countriesDarkGeoPackagePath = [[NSBundle mainBundle] pathForResource:@"countries_dark" ofType:@"gpkg"];
    NSLog(@"Countries GeoPackage path %@", countriesDarkGeoPackagePath);
    
    // Add the GeoPackage caches
    GPKGGeoPackageManager * manager = [GPKGGeoPackageFactory manager];
    if (![manager exists:@"countries_dark"]) {
        @try {
            [manager importGeoPackageFromPath:countriesDarkGeoPackagePath];
        }
        @catch (NSException *e) {
            // probably was already imported and that is fine
        }
    }

    self.darkBackgroundGeoPackage = [manager open:@"countries_dark"];
    if (self.darkBackgroundGeoPackage) {
        @try {
            GPKGFeatureDao * darkFeatureDao = [self.darkBackgroundGeoPackage featureDaoWithTableName:@"countries"];
            
            // If indexed, add as a tile overlay
            GPKGFeatureTiles * darkFeatureTiles = [[GPKGFeatureTiles alloc] initWithGeoPackage:self.darkBackgroundGeoPackage andFeatureDao:darkFeatureDao];
            [darkFeatureTiles setIndexManager:[[GPKGFeatureIndexManager alloc] initWithGeoPackage:self.darkBackgroundGeoPackage andFeatureDao:darkFeatureDao]];
            
            self.darkBackgroundOverlay = [[BaseMapOverlay alloc] initWithFeatureTiles:darkFeatureTiles];
            [self.darkBackgroundOverlay setMinZoom:0];
            self.darkBackgroundOverlay.darkTheme = YES;
            
            self.darkBackgroundOverlay.canReplaceMapContent = true;
            }
            @catch (NSException *e) {
                NSLog(@"Exception initializing the dark base map GP %@", e);
            }
    }
    
    return self.darkBackgroundOverlay;
}

- (void) applicationWillTerminate:(UIApplication *) application {
    NSLog(@"applicationWillTerminate");

    [MagicalRecord cleanUp];
}

- (void)tokenDidExpire:(NSNotification *)notification {
    [[Mage singleton] stopServices];
    [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
    [self createRootView];
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}
@end

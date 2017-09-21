//
//  AppDelegate.m
//  Mage
//
//

#import "AppDelegate.h"
#import <Mage.h>
#import <User.h>
#import <CoreLocation/CoreLocation.h>
#import <FICImageCache.h>
#import <UserUtility.h>
#import <UserNotifications/UserNotifications.h>
#import "Attachment.h"
#import "Attachment+Thumbnail.h"
#import "UIImage+Thumbnail.h"

#import "MageInitialViewController.h"
#import "LoginViewController.h"

#import "OZZipFile+OfflineMap.h"
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import <MageSessionManager.h>

#import "MagicalRecord+MAGE.h"
#import "GPKGGeoPackageFactory.h"
#import "GPKGGeoPackageValidate.h"
#import "CacheOverlays.h"
#import "XYZDirectoryCacheOverlay.h"
#import "GeoPackageCacheOverlay.h"
#import "GeoPackageTableCacheOverlay.h"
#import "GeoPackageTileTableCacheOverlay.h"
#import "GPKGFeatureIndexManager.h"
#import "GeoPackageFeatureTableCacheOverlay.h"
#import "MageConstants.h"
#import "GPKGFeatureTileTableLinker.h"
#import "MageOfflineObservationManager.h"
#import "UIColor+UIColor_Mage.h"
#import <Server.h>
#import "MageAppCoordinator.h"
#import <GoogleSignIn/GoogleSignIn.h>

@interface AppDelegate () <UNUserNotificationCenterDelegate>
@property (nonatomic, strong) UIView *splashView;
@property (nonatomic, strong) NSManagedObjectContext *pushManagedObjectContext;
@property (nonatomic, strong) NSString *addedCacheOverlay;
@property (nonatomic, strong) MageAppCoordinator *appCoordinator;
@property (nonatomic, strong) UINavigationController *rootViewController;
@property (nonatomic, strong) UIApplication *application;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
    
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenDidExpire:) name: MAGETokenExpiredNotification object:nil];
    NSURL *sdkPreferencesFile = [[NSBundle mainBundle] URLForResource:@"MageSDK.bundle/preferences" withExtension:@"plist"];
    NSDictionary *sdkPreferences = [NSDictionary dictionaryWithContentsOfURL:sdkPreferencesFile];
    
    NSURL *defaultPreferencesFile = [[NSBundle mainBundle] URLForResource:@"preferences" withExtension:@"plist"];
    NSDictionary *defaultPreferences = [NSDictionary dictionaryWithContentsOfURL:defaultPreferencesFile];
    
    NSMutableDictionary *allPreferences = [[NSMutableDictionary alloc] initWithDictionary:sdkPreferences];
    [allPreferences addEntriesFromDictionary:defaultPreferences];
    [[NSUserDefaults standardUserDefaults]  registerDefaults:allPreferences];
    
    [MagicalRecord setupMageCoreDataStack];
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelVerbose];
    
    [self setupApplicationNavigationBar];
    
    self.window = [[UIWindow alloc] initWithFrame: [UIScreen mainScreen].bounds];
    [self.window makeKeyAndVisible];

    [self createRootView];
    
	return YES;
}

- (BOOL)application:(UIApplication *)app
            openURL:(NSURL *)url
            options:(NSDictionary *)options {
    NSLog(@"URL %@", url);
    if ([[url scheme] hasPrefix:@"com.googleusercontent.apps"]) {
        return [[GIDSignIn sharedInstance] handleURL:url
                               sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                                      annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
    }
    return false;
}

- (void) createRootView {
    self.rootViewController = [[UINavigationController alloc] init];
    self.rootViewController.navigationBarHidden = YES;
    [self.window setRootViewController:self.rootViewController];
    UIViewController *transitionView = [[UIViewController alloc] initWithNibName:@"TransitionScreen" bundle:nil];
    [self.rootViewController pushViewController:transitionView animated:NO];
    self.appCoordinator = [[MageAppCoordinator alloc] initWithNavigationController:self.rootViewController forApplication:self.application];
    [self.appCoordinator start];
}

- (void) chooseEvent {
    [Server removeCurrentEventId];
    [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
    [self createRootView];
}

- (void) logout {
    [[UserUtility singleton] expireToken];
    [[Mage singleton] stopServices];
    [[LocationService singleton] stop];
    [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
    [self createRootView];
}

- (void) application: (UIApplication *) application performFetchWithCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler {
    NSLog(@"background fetch");
    
    NSURLSessionDataTask *observationFetchTask = [Observation operationToPullObservationsWithSuccess:^{
        completionHandler(UIBackgroundFetchResultNewData);
    } failure:^(NSError* error) {
        completionHandler(UIBackgroundFetchResultFailed);
    }];
    
    [[MageSessionManager manager] addTask:observationFetchTask];
}

- (void) setupApplicationNavigationBar {
    [[UINavigationBar appearance] setBarTintColor:[UIColor mageBlue]];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:@{
                                                           NSForegroundColorAttributeName: [UIColor whiteColor]
                                                           }];
    [[UINavigationBar appearance] setTranslucent:NO];
}

- (void) applicationDidEnterBackground:(UIApplication *) application {
    NSLog(@"applicationDidEnterBackground");
    
    self.splashView = [[UIView alloc]initWithFrame:[self.window frame]];
    self.splashView.backgroundColor = [UIColor colorWithRed:17.0/255 green:84.0/255 blue:164.0/255 alpha:1];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:(CGRectMake(0, 0, 240, 45))];
    imageView.image = [UIImage imageNamed:@"mage_logo"];
    imageView.contentMode = UIViewContentModeScaleAspectFit;
    [imageView setCenter:CGPointMake(self.splashView.bounds.size.width/2, self.splashView.bounds.size.height/2)];
    
    [self.splashView addSubview:imageView];
    [self.window addSubview:self.splashView];
    
    [[Mage singleton] stopServices];
}

- (void) applicationWillResignActive:(UIApplication *)application {
    application.applicationIconBadgeNumber = [MageOfflineObservationManager offlineObservationCount];
}

- (void) applicationWillEnterForeground:(UIApplication *) application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"applicationWillEnterForeground");
    if (![[UserUtility singleton] isTokenExpired]) {
        [[Mage singleton] startServicesAsInitial:NO];
    }
}

- (void) applicationDidBecomeActive:(UIApplication *) application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSLog(@"applicationDidBecomeActive");
    
    if(self.splashView != nil) {
        [self.splashView removeFromSuperview];
        self.splashView = nil;
    }
    
    [self processOfflineMapArchives];
}

- (void) application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler {
    // Handle attachments uploaded in the background
    if ([identifier isEqualToString:kAttachmentBackgroundSessionIdentifier]) {
        NSLog(@"ATTACHMENT - AppDelegate handleEventsForBackgroundURLSession");
        AttachmentPushService *service = [AttachmentPushService singleton];
        service.backgroundSessionCompletionHandler = completionHandler;
    }
}

- (void) processOfflineMapArchives {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    NSArray *directoryContent = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:documentsDirectory error:NULL];
    NSArray *archives = [directoryContent filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension == %@ AND SELF != %@", @"zip", @"Form.zip"]];
    
    CacheOverlays * cacheOverlays = [CacheOverlays getInstance];
    [cacheOverlays addProcessingFromArray:archives];
    
    NSString * baseCacheDirectory = [documentsDirectory stringByAppendingPathComponent:MAGE_CACHE_DIRECTORY];
    
    // Add the existing cache directories
    NSMutableArray<CacheOverlay *> * overlays = [[NSMutableArray alloc] init];
    NSArray* caches = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:baseCacheDirectory error:nil];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for(NSString * cache in caches){
        NSString * cacheDirectory = [baseCacheDirectory stringByAppendingPathComponent:cache];
        BOOL isDirectory = NO;
        [fileManager fileExistsAtPath:cacheDirectory isDirectory:&isDirectory];
        if(isDirectory){
            CacheOverlay * cacheOverlay = [[XYZDirectoryCacheOverlay alloc] initWithName:cache andDirectory:cacheDirectory];
            [overlays addObject:cacheOverlay];
        }
    }
    
    // Import any GeoPackage files that were dropped in
    NSArray *geoPackageFiles = [directoryContent filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension == %@ OR pathExtension == %@", @"gpkg", @"gpkx"]];
    for(NSString * geoPackageFile in geoPackageFiles){
        // Import the GeoPackage file
        NSString * geoPackagePath = [documentsDirectory stringByAppendingPathComponent:geoPackageFile];
        [self importGeoPackageFile:geoPackagePath];
    }
    
    // Add the GeoPackage cache overlays
    [self addGeoPackageCacheOverlays:overlays];
    
    // Determine which caches are enabled
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableSet * selectedCaches = [NSMutableSet setWithArray:[defaults objectForKey:MAGE_SELECTED_CACHES]];
    if([selectedCaches count] > 0){
        
        for (CacheOverlay * cacheOverlay in overlays) {
            
            // Check and enable the cache
            NSString *  cacheName = [cacheOverlay getCacheName];
            BOOL enabled = [selectedCaches containsObject:cacheName];
            
            // Check the child caches
            BOOL enableParent = false;
            for (CacheOverlay * childCache in [cacheOverlay getChildren]) {
                if (enabled || [selectedCaches containsObject:[childCache getCacheName]]) {
                    [childCache setEnabled:true];
                    enableParent = true;
                }
            }
            if(enabled || enableParent){
                [cacheOverlay setEnabled:true];
            }
            
            // Mark the cache overlay if MAGE was launched with a new cache file
            if(self.addedCacheOverlay != nil && [self.addedCacheOverlay isEqualToString:cacheName]){
                [cacheOverlay setAdded:true];
            }
        }
    }
    self.addedCacheOverlay = nil;
    
    [[CacheOverlays getInstance] addCacheOverlays:overlays];
    
    for (id archive in archives) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
            [self processArchiveAtFilePath:[NSString stringWithFormat:@"%@/%@", documentsDirectory, archive] toDirectory:baseCacheDirectory];
        });
    }
}

-(void) addGeoPackageCacheOverlays:(NSMutableArray<CacheOverlay *> *) cacheOverlays{
    // Add the GeoPackage caches
    GPKGGeoPackageManager * manager = [GPKGGeoPackageFactory getManager];
    NSArray * geoPackages = [manager databases];
    for(NSString * geoPackage in geoPackages){
        
        // Make sure the GeoPackage file exists
        NSString * filePath = [manager documentsPathForDatabase:geoPackage];
        if(filePath != nil && [[NSFileManager defaultManager] fileExistsAtPath:filePath]){
        
            GeoPackageCacheOverlay * cacheOverlay = [self getGeoPackageCacheOverlayWithManager:manager andName:geoPackage];
            if(cacheOverlay != nil){
                [cacheOverlays addObject:cacheOverlay];
            }
        }else{
            // Delete if the file was deleted
            [manager delete:geoPackage];
        }
    }
}

-(GeoPackageCacheOverlay *) getGeoPackageCacheOverlayWithManager: (GPKGGeoPackageManager *) manager andName: (NSString *) name{
    
    GeoPackageCacheOverlay * cacheOverlay = nil;
    
    // Add the GeoPackage overlay
    GPKGGeoPackage * geoPackage = [manager open:name];
    @try {
        NSMutableArray<GeoPackageTableCacheOverlay *> * tables = [[NSMutableArray alloc] init];
        
        // GeoPackage tile tables, build a mapping between table name and the created cache overlays
        NSMutableDictionary<NSString *, GeoPackageTileTableCacheOverlay *> * tileCacheOverlays = [[NSMutableDictionary alloc] init];
        NSArray * tileTables = [geoPackage getTileTables];
        for(NSString * tileTable in tileTables){
            NSString * tableCacheName = [CacheOverlay buildChildCacheNameWithName:name andChildName:tileTable];
            GPKGTileDao * tileDao = [geoPackage getTileDaoWithTableName:tileTable];
            int count = [tileDao count];
            int minZoom = tileDao.minZoom;
            int maxZoom = tileDao.maxZoom;
            GeoPackageTileTableCacheOverlay * tableCache = [[GeoPackageTileTableCacheOverlay alloc] initWithName:tileTable andGeoPackage:name andCacheName:tableCacheName andCount:count andMinZoom:minZoom andMaxZoom:maxZoom];
            [tileCacheOverlays setObject:tableCache forKey:tileTable];
        }
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        // Get a linker to find tile tables linked to features
        GPKGFeatureTileTableLinker * linker = [[GPKGFeatureTileTableLinker alloc] initWithGeoPackage:geoPackage];
        NSMutableDictionary<NSString *, GeoPackageTileTableCacheOverlay *> * linkedTileCacheOverlays = [[NSMutableDictionary alloc] init];
        
        // GeoPackage feature tables
        NSArray * featureTables = [geoPackage getFeatureTables];
        for(NSString * featureTable in featureTables){
            NSString * tableCacheName = [CacheOverlay buildChildCacheNameWithName:name andChildName:featureTable];
            GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:featureTable];
            int count = [featureDao count];
            enum WKBGeometryType geometryType = [featureDao getGeometryType];
            GPKGFeatureIndexManager * indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
            BOOL indexed = [indexer isIndexed];
            int minZoom = 0;
            if(indexed){
                minZoom = [featureDao getZoomLevel] + (int)[defaults integerForKey:@"geopackage_feature_tiles_min_zoom_offset"];
                minZoom = MAX(minZoom, 0);
                minZoom = MIN(minZoom, (int)MAGE_FEATURES_MAX_ZOOM);
            }
            GeoPackageFeatureTableCacheOverlay * tableCache = [[GeoPackageFeatureTableCacheOverlay alloc] initWithName:featureTable andGeoPackage:name andCacheName:tableCacheName andCount:count andMinZoom:minZoom andIndexed:indexed andGeometryType:geometryType];
            
            // If indexed, check for linked tile tables
            if(indexed){
                NSArray<NSString *> * linkedTileTables = [linker getTileTablesForFeatureTable:featureTable];
                for(NSString * linkedTileTable in linkedTileTables){
                    // Get the tile table cache overlay
                    GeoPackageTileTableCacheOverlay * tileCacheOverlay = [tileCacheOverlays objectForKey:linkedTileTable];
                    if(tileCacheOverlay != nil){
                        // Remove from tile cache overlays so the tile table is not added as stand alone, and add to the linked overlays
                        [tileCacheOverlays removeObjectForKey:linkedTileTable];
                        [linkedTileCacheOverlays setObject:tileCacheOverlay forKey:linkedTileTable];
                    }else{
                        // Another feature table may already be linked to this table, so check the linked overlays
                        tileCacheOverlay = [linkedTileCacheOverlays objectForKey:linkedTileTable];
                    }
                    
                    // Add the linked tile table to the feature table
                    if(tileCacheOverlay != nil){
                        [tableCache addLinkedTileTable:tileCacheOverlay];
                    }
                }
            }
            
            [tables addObject:tableCache];
        }
        
        // Add stand alone tile tables that were not linked to feature tables
        for(GeoPackageTileTableCacheOverlay * tileCacheOverlay in [tileCacheOverlays allValues]){
            [tables addObject: tileCacheOverlay];
        }
        
        // Create the GeoPackage overlay with child tables
        cacheOverlay = [[GeoPackageCacheOverlay alloc] initWithName:name andTables:tables];
    }
    @finally {
        [geoPackage close];
    }
    
    return cacheOverlay;
}

- (void) processArchiveAtFilePath:(NSString *) archivePath toDirectory:(NSString *) directory {
    NSLog(@"File %@", archivePath);
    
    NSError *error = nil;
    OZZipFile *zipFile = [[OZZipFile alloc] initWithFileName:archivePath mode:OZZipFileModeUnzip error:nil];
    NSArray *caches = [zipFile expandToPath:directory error:&error];
    if (error) {
        NSLog(@"Error extracting offline map archive: %@. Error: %@", archivePath, error);
    }
    
    CacheOverlays *cacheOverlays = [CacheOverlays getInstance];
    
    if (caches.count) {
        for(NSString * cache in caches){
            CacheOverlay * cacheOverlay = [[XYZDirectoryCacheOverlay alloc] initWithName:cache andDirectory:[directory stringByAppendingPathComponent:cache]];
            [cacheOverlays addCacheOverlay:cacheOverlay];
        }
    }
    
    [cacheOverlays removeProcessing:[archivePath lastPathComponent]];
    
    error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:archivePath error:&error];
    if (error) {
        NSLog(@"Error deleting extracted offline map archive: %@. Error: %@", archivePath, error);
    }
}

- (void) applicationWillTerminate:(UIApplication *) application {
    NSLog(@"applicationWillTerminate");

    [MagicalRecord cleanUp];
}

- (void)tokenDidExpire:(NSNotification *)notification {
    [[Mage singleton] stopServices];
    
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    
    UNMutableNotificationContent* content = [[UNMutableNotificationContent alloc] init];
    content.title = @"MAGE Token Expired";
    content.body = @"Your MAGE token has expired.";
    content.categoryIdentifier = @"TokenExpired";
    content.sound = [UNNotificationSound defaultSound];
    
    UNTimeIntervalNotificationTrigger* trigger = [UNTimeIntervalNotificationTrigger
                                                  triggerWithTimeInterval:1 repeats:NO];
    UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:@"TokenExpired"
                                                                          content:content trigger:trigger];
    
    [center addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"Something went wrong: %@",error);
        }
        NSLog(@"notification");
    }];
    
    UIViewController *currentController = [self topMostController];
    if (!([currentController isKindOfClass:[MageInitialViewController class]]
        || [currentController isKindOfClass:[LoginViewController class]]
        || [currentController.restorationIdentifier isEqualToString:@"DisclaimerScreen"])) {
        [self.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

- (UIViewController*) topMostController
{
    UIViewController *topController = self.window.rootViewController;
    
    while (topController.presentedViewController) {
        topController = topController.presentedViewController;
    }
    
    return topController;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (BOOL) application:(UIApplication *)application openURL:(NSURL *) url sourceApplication:(NSString *) sourceApplication annotation:(id) annotation {
    
    if (!url) {
        return NO;
    }
    
    if (url.isFileURL) {
        NSString * fileUrl = [url path];
        
        // Handle GeoPackage files
        if([GPKGGeoPackageValidate hasGeoPackageExtension:fileUrl]){
        
            // Import the GeoPackage file
            if([self importGeoPackageFile:fileUrl]){
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                NSMutableSet * selectedCaches = [NSMutableSet setWithArray:[defaults objectForKey:MAGE_SELECTED_CACHES]];
                NSString * name = [[fileUrl lastPathComponent] stringByDeletingPathExtension];
                [selectedCaches addObject:name];
                [defaults setObject:[selectedCaches allObjects] forKey:MAGE_SELECTED_CACHES];
                [defaults synchronize];
                self.addedCacheOverlay = name;
            }
        }
    }
    
    return YES;
}

-(BOOL) importGeoPackageFile: (NSString *) path{
    // Import the GeoPackage file
    BOOL imported = false;
    GPKGGeoPackageManager * manager = [GPKGGeoPackageFactory getManager];
    @try {
        imported = [manager importGeoPackageFromPath:path andOverride:true andMove:true];
    }
    @finally {
        [manager close];
    }
    
    if(!imported){
        NSLog(@"Error importing GeoPackage file: %@", path);
    }
    
    return imported;
}

@end

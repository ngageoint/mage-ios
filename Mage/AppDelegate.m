//
//  AppDelegate.m
//  Mage
//
//

#import "AppDelegate.h"
#import "Mage.h"
#import "User.h"
#import "Canary.h"
#import <CoreLocation/CoreLocation.h>
#import "UserUtility.h"
#import <UserNotifications/UserNotifications.h>
#import "Attachment.h"
#import "UIImage+Thumbnail.h"

#import "MageInitialViewController.h"
#import "LoginViewController.h"

#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import "MageSessionManager.h"

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
#import "Server.h"
#import "MageAppCoordinator.h"
#import "TransitionViewController.h"
#import "Layer.h"
#import "MageConstants.h"
#import "MageInitializer.h"
#import "MAGE-Swift.h"
#import <SSZipArchive/SSZipArchive.h>

@interface AppDelegate () <UNUserNotificationCenterDelegate, SSZipArchiveDelegate>
@property (nonatomic, strong) TransitionViewController *splashView;
@property (nonatomic, strong) NSManagedObjectContext *pushManagedObjectContext;
@property (nonatomic, strong) NSString *addedCacheOverlay;
@property (nonatomic, strong) MageAppCoordinator *appCoordinator;
@property (nonatomic, strong) UINavigationController *rootViewController;
@property (nonatomic, strong) UIApplication *application;
@property (nonatomic) BOOL applicationStarted;
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
    
    [self createLoadingView];
    
    NSLog(@"Finish Launching Protected data is available? %d", protectedDataAvailable);
    
    if (protectedDataAvailable) {
        [self setupMageApplication:application];
        [self startMageApp];
    }
    
    if (@available(iOS 13.0, *)) {
    } else {
        [[UITextField appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setTextColor:[UIColor whiteColor]];
    }

	return YES;
}

- (void) setupMageApplication: (UIApplication *) application {
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenDidExpire:) name: MAGETokenExpiredNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(geoPackageDownloaded:) name:GeoPackageDownloaded object:nil];
    
    [MageInitializer initializePreferences];
    [MageInitializer setupCoreData];
}

- (void) geoPackageDownloaded: (NSNotification *) notification {
    NSString *filePath = [notification.userInfo valueForKey:@"filePath"];
    [self importGeoPackageFileAsLink:filePath andMove:NO withLayerId:[notification.userInfo valueForKey:@"layerId"]];
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
        if([GPKGGeoPackageValidate hasGeoPackageExtension:filePath]){
            
            if ([self isGeoPackageAlreadyImported:[[filePath lastPathComponent] stringByDeletingPathExtension]]) {
                
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Overwrite Existing GeoPackage?"
                                                                               message:[NSString stringWithFormat:@"A GeoPackage with the name %@ already exists.  You can import it as a new GeoPackage, or overwrite the existing GeoPackage.", [[filePath lastPathComponent] stringByDeletingPathExtension]]
                                                                        preferredStyle:UIAlertControllerStyleActionSheet];
                
                [alert addAction:[UIAlertAction actionWithTitle:@"Import As New" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    // rename it and import
                    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                    [formatter setDateFormat:@"yyyy-MM-dd_HH:mm:ss"];
                    NSLocale *posix = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
                    [formatter setLocale:posix];
                    
                    [self importGeoPackageFile:filePath withName:[NSString stringWithFormat:@"%@_%@", [[filePath lastPathComponent] stringByDeletingPathExtension], [formatter stringFromDate:[NSDate date]]] andOverwrite:NO];
                }]];
                [alert addAction:[UIAlertAction actionWithTitle:@"Overwrite Existing GeoPackage" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                    [self importGeoPackageFile: filePath andOverwrite:YES];
                }]];
                [alert addAction:[UIAlertAction actionWithTitle:@"Do Not Import" style:UIAlertActionStyleCancel handler:nil]];
                
                [[AppDelegate topMostController] presentViewController:alert animated:YES completion:nil];
            } else {
                // Import the GeoPackage file
                [self importGeoPackageFile: filePath andOverwrite:NO];
            }
        }
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

-(void) updateSelectedCaches: (NSString *) name {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableSet * selectedCaches = [NSMutableSet setWithArray:[defaults objectForKey:MAGE_SELECTED_CACHES]];
    [selectedCaches addObject:name];
    [defaults setObject:[selectedCaches allObjects] forKey:MAGE_SELECTED_CACHES];
    [defaults synchronize];
    self.addedCacheOverlay = name;
}

- (void) createLoadingView {
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
            [self processOfflineMapArchives];
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
        [[Mage singleton] startServicesAsInitial:NO];
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
                
                [self processOfflineMapArchives];
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

- (void) removeOutdatedOfflineMapArchives {
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
        NSArray * layers = [Layer MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"eventId == -1 AND (type == %@ OR type == %@)", [Server currentEventId], @"GeoPackage", @"Local_XYZ"] inContext:localContext];
        for (Layer * layer in layers) {
            CacheOverlay * overlay =  [[CacheOverlays getInstance] getByCacheName:layer.name];
            if (!overlay) {
                [layer MR_deleteEntity];
            }
            else if ([overlay isKindOfClass:[GeoPackageCacheOverlay class]]) {
                GeoPackageCacheOverlay *gpOverlay = (GeoPackageCacheOverlay *)overlay;
                if (!overlay || ![[NSFileManager defaultManager] fileExistsAtPath:gpOverlay.filePath]) {
                    [layer MR_deleteEntity];
                }
            }
        }
    }];
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
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                Layer *l = [Layer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"eventId == -1 AND (type == %@ OR type == %@) AND name == %@", @"GeoPackage", @"Local_XYZ", cache] inContext:localContext];
                if (!l) {
                    l = [Layer MR_createEntityInContext:localContext];
                    l.name = cache;
                    l.loaded = [NSNumber numberWithFloat:EXTERNAL_LAYER_LOADED];
                    l.type = @"Local_XYZ";
                    l.eventId = [NSNumber numberWithInt:-1];
                }
            }];
        }
    }
    
    // Import any GeoPackage files that were dropped in
    NSArray *geoPackageFiles = [directoryContent filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension == %@ OR pathExtension == %@", @"gpkg", @"gpkx"]];
    for(NSString * geoPackageFile in geoPackageFiles){
        // Import the GeoPackage file
        NSString * geoPackagePath = [documentsDirectory stringByAppendingPathComponent:geoPackageFile];
        [self importGeoPackageFile:geoPackagePath andOverwrite:NO];
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
    [self removeOutdatedOfflineMapArchives];
}

-(void) addGeoPackageCacheOverlays:(NSMutableArray<CacheOverlay *> *) cacheOverlays{
    
    NSString *countriesDarkGeoPackagePath = [[NSBundle mainBundle] pathForResource:@"countries_dark" ofType:@"gpkg"];
    NSLog(@"Countries GeoPackage path %@", countriesDarkGeoPackagePath);
    
    // Add the GeoPackage caches
    GPKGGeoPackageManager * manager = [GPKGGeoPackageFactory manager];
    @try {
        [manager importGeoPackageFromPath:countriesDarkGeoPackagePath];
    }
    @catch (NSException *e) {
        // probably was already imported and that is fine
    }
    NSString *countriesGeoPackagePath = [[NSBundle mainBundle] pathForResource:@"countries" ofType:@"gpkg"];
    NSLog(@"Countries GeoPackage path %@", countriesGeoPackagePath);
    @try {
        [manager importGeoPackageFromPath:countriesGeoPackagePath];
    }
    @catch (NSException *e) {
        // probably was already imported and that is fine
    }
    @try {
        //databases call only returns the geopacakge if it is named the same as the name of the actual file on disk
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
                [[CacheOverlays getInstance] removeByCacheName:[[filePath lastPathComponent] stringByDeletingPathExtension]];
                // Delete if the file was deleted
                [manager delete:geoPackage];
            }
        }
    }
    @catch (NSException *e) {
        NSLog(@"Problem getting GeoPackages %@", e);
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
        NSArray * tileTables = [geoPackage tileTables];
        for(NSString * tileTable in tileTables){
            NSString * tableCacheName = [CacheOverlay buildChildCacheNameWithName:name andChildName:tileTable];
            GPKGTileDao * tileDao = [geoPackage tileDaoWithTableName:tileTable];
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
        NSArray * featureTables = [geoPackage featureTables];
        for(NSString * featureTable in featureTables){
            NSString * tableCacheName = [CacheOverlay buildChildCacheNameWithName:name andChildName:featureTable];
            GPKGFeatureDao * featureDao = [geoPackage featureDaoWithTableName:featureTable];
            int count = [featureDao count];
            enum SFGeometryType geometryType = [featureDao geometryType];
            GPKGFeatureIndexManager * indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
            BOOL indexed = [indexer isIndexed];
            int minZoom = 0;
            if(indexed){
                minZoom = [featureDao zoomLevel] + (int)[defaults integerForKey:@"geopackage_feature_tiles_min_zoom_offset"];
                minZoom = MAX(minZoom, 0);
                minZoom = MIN(minZoom, (int)MAGE_FEATURES_MAX_ZOOM);
            }
            GeoPackageFeatureTableCacheOverlay * tableCache = [[GeoPackageFeatureTableCacheOverlay alloc] initWithName:featureTable andGeoPackage:name andCacheName:tableCacheName andCount:count andMinZoom:minZoom andIndexed:indexed andGeometryType:geometryType];
            
            // If indexed, check for linked tile tables
            if(indexed){
                NSArray<NSString *> * linkedTileTables = [linker tileTablesForFeatureTable:featureTable];
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
        cacheOverlay = [[GeoPackageCacheOverlay alloc] initWithName:name andPath: geoPackage.path andTables:tables];
    }
    @catch (NSException *exception) {
        NSLog(@"Failed to import GeoPackage %@", exception);
    }
    @finally {
        [geoPackage close];
    }
    
    return cacheOverlay;
}

- (void) finishDidUnzipAtPath:(NSString *)path zipInfo:(unz_global_info)zipInfo unzippedPath:(NSString *)unzippedPath {
    CacheOverlays *cacheOverlays = [CacheOverlays getInstance];

    [cacheOverlays removeProcessing:[path lastPathComponent]];

    // There is no way to know what was in the zip that was unarchived, so just add all current caches to the list
    NSArray* caches = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:unzippedPath error:nil];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    for(NSString * cache in caches){
        NSString * cacheDirectory = [unzippedPath stringByAppendingPathComponent:cache];
        BOOL isDirectory = NO;
        [fileManager fileExistsAtPath:cacheDirectory isDirectory:&isDirectory];
        if(isDirectory){
            CacheOverlay * cacheOverlay = [[XYZDirectoryCacheOverlay alloc] initWithName:cache andDirectory:cacheDirectory];
            [cacheOverlays addCacheOverlay:cacheOverlay];
            NSLog(@"Imported local XYZ Zip");
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                Layer *l = [Layer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"eventId == -1 AND (type == %@ OR type == %@) AND name == %@", @"GeoPackage", @"Local_XYZ", cache] inContext:localContext];
                if (!l) {
                    l = [Layer MR_createEntityInContext:localContext];
                    l.name = cache;
                    l.loaded = [NSNumber numberWithFloat:EXTERNAL_LAYER_LOADED];
                    l.type = @"Local_XYZ";
                    l.eventId = [NSNumber numberWithInt:-1];
                }
            }];
        }
    }
}

#pragma mark - SSZipArchiveDelegate methods
- (void) zipArchiveDidUnzipArchiveAtPath:(NSString *)path zipInfo:(unz_global_info)zipInfo unzippedPath:(NSString *)unzippedPath {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self finishDidUnzipAtPath:path zipInfo:zipInfo unzippedPath:unzippedPath];
    });
}
#pragma mark -

- (void) processArchiveAtFilePath:(NSString *) archivePath toDirectory:(NSString *) directory {
    NSError *error = nil;
    [SSZipArchive unzipFileAtPath:archivePath toDestination:directory delegate:self];
    if ([[NSFileManager defaultManager] isDeletableFileAtPath:archivePath]) {
        BOOL successfulRemoval = [[NSFileManager defaultManager] removeItemAtPath:archivePath error:&error];
        if (!successfulRemoval) {
            NSLog(@"Error removing file at path: %@", error.localizedDescription);
        }
    }
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

-(BOOL) isGeoPackageAlreadyImported: (NSString *) name {
    GPKGGeoPackageManager * manager = [GPKGGeoPackageFactory manager];
    return [[manager databasesLike:name] count] != 0;
}

-(BOOL) importGeoPackageFile: (NSString *) path withName: (NSString *) name andOverwrite: (BOOL) overwrite {
    // Import the GeoPackage file
    BOOL imported = false;
    GPKGGeoPackageManager * manager = [GPKGGeoPackageFactory manager];
    @try {
        BOOL alreadyImported = [self isGeoPackageAlreadyImported:name];
        imported = [manager importGeoPackageFromPath:path withName:name andOverride:overwrite andMove:true];
        NSLog(@"Imported local Geopackage %d", imported);
        if (imported && !alreadyImported) {
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                Layer *l = [Layer MR_createEntityInContext:localContext];
                l.name = name;
                l.loaded = [NSNumber numberWithFloat:EXTERNAL_LAYER_LOADED];
                l.type = @"GeoPackage";
                l.eventId = [NSNumber numberWithInt:-1];
                [self updateSelectedCaches:name];
            }];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Failed to import GeoPackage %@", exception);
    }
    @finally {
        [manager close];
    }
    
    if(!imported){
        NSLog(@"Error importing GeoPackage file: %@", path);
    } else {
        [self processOfflineMapArchives];
    }
    
    return imported;
}

-(BOOL) importGeoPackageFile: (NSString *) path andOverwrite: (BOOL) overwrite{
    return [self importGeoPackageFile:path withName:[[path lastPathComponent] stringByDeletingPathExtension] andOverwrite:overwrite];
}

-(BOOL) importGeoPackageFile: (NSString *) path {
    return [self importGeoPackageFile:path andOverwrite:YES];
}

-(BOOL) importGeoPackageFileAsLink: (NSString *) path andMove: (BOOL) moveFile withLayerId: (NSString *) remoteId {
    // Import the GeoPackage file
    BOOL imported = false;
    GPKGGeoPackageManager * manager = [GPKGGeoPackageFactory manager];
    @try {
        NSArray *alreadyImported = [manager databasesLike:[[path lastPathComponent] stringByDeletingPathExtension]];
        if ([alreadyImported count] == 1) {
            imported = YES;
        } else {
            imported = [manager importGeoPackageAsLinkToPath:path withName:[[path lastPathComponent] stringByDeletingPathExtension]];
        }
    }
    @catch (NSException *exception) {
        NSLog(@"Failed to import GeoPackage %@", exception);
    }
    @finally {
        [manager close];
    }
    
    if(!imported){
        NSLog(@"Error importing GeoPackage file: %@", path);
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
            NSArray<Layer *> *layers = [Layer MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"remoteId == %@", remoteId] inContext:localContext];
            for (Layer *layer in layers) {
                layer.loaded = [NSNumber numberWithFloat: OFFLINE_LAYER_NOT_DOWNLOADED];
                layer.downloading = NO;
            }
        }];
    } else {
        NSLog(@"GeoPackage file %@ has been imported", path);
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
            NSArray<Layer *> *layers = [Layer MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"remoteId == %@", remoteId] inContext:localContext];
            for (Layer *layer in layers) {
                layer.loaded = [NSNumber numberWithInteger: OFFLINE_LAYER_LOADED];
                layer.downloading = NO;
            }
        } completion:^(BOOL contextDidSave, NSError * _Nullable magicalRecordError) {
            [self processOfflineMapArchives];
            [[NSNotificationCenter defaultCenter] postNotificationName:GeoPackageImported object:nil];
        }];
    }
    
    return imported;
}

@end

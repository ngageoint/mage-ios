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
#import "FICImageCache.h"
#import "UserUtility.h"
#import <UserNotifications/UserNotifications.h>
#import "Attachment.h"
#import "Attachment+Thumbnail.h"
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
#import <GoogleSignIn/GoogleSignIn.h>
#import "TransitionViewController.h"
#import "Theme+UIResponder.h"
#import "Layer.h"
#import "MageConstants.h"
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
    
    NSLog(@"Protected data is available? %d", protectedDataAvailable);
    
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
    NSURL *sdkPreferencesFile = [[NSBundle mainBundle] URLForResource:@"MageSDK.bundle/preferences" withExtension:@"plist"];
    NSDictionary *sdkPreferences = [NSDictionary dictionaryWithContentsOfURL:sdkPreferencesFile];
    
    NSURL *defaultPreferencesFile = [[NSBundle mainBundle] URLForResource:@"preferences" withExtension:@"plist"];
    NSDictionary *defaultPreferences = [NSDictionary dictionaryWithContentsOfURL:defaultPreferencesFile];
    
    NSMutableDictionary *allPreferences = [[NSMutableDictionary alloc] initWithDictionary:sdkPreferences];
    [allPreferences addEntriesFromDictionary:defaultPreferences];
    [[NSUserDefaults standardUserDefaults]  registerDefaults:allPreferences];
    
    [MagicalRecord setupMageCoreDataStack];
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelVerbose];
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
    
    NSLog(@"URL %@", url);
    if ([[url scheme] hasPrefix:@"com.googleusercontent.apps"]) {
        return [[GIDSignIn sharedInstance] handleURL:url
                               sourceApplication:options[UIApplicationOpenURLOptionsSourceApplicationKey]
                                      annotation:options[UIApplicationOpenURLOptionsAnnotationKey]];
    } else if (url.isFileURL) {
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

- (void) createLoadingView {
    self.rootViewController = [[UINavigationController alloc] init];
    self.rootViewController.navigationBarHidden = YES;
    [self.window setRootViewController:self.rootViewController];
    TransitionViewController *transitionView = [[TransitionViewController alloc] initWithNibName:@"TransitionScreen" bundle:nil];
    transitionView.modalPresentationStyle = UIModalPresentationFullScreen;
    [self.rootViewController pushViewController:transitionView animated:NO];
}

- (void) startMageApp {
    // do a canary save
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
        Canary *canary = [Canary MR_findFirstInContext:localContext];
        if (!canary) {
            canary = [Canary MR_createEntityInContext:localContext];
        }
        canary.launchDate = [NSDate date];
    } completion:^(BOOL contextDidSave, NSError * _Nullable error) {
        // error should be null and contextDidSave should be true
        if (contextDidSave && error == NULL) {
            self.appCoordinator = [[MageAppCoordinator alloc] initWithNavigationController:self.rootViewController forApplication:self.application];
            [self.appCoordinator start];
        } else {
            NSLog(@"Could not read or write from the database");
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"iOS Data Unavailable"
                                                                           message:@"It appears the app data is unavailable at this time.  If this continues, please notify your administrator."
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            
            [self.rootViewController presentViewController:alert animated:YES completion:nil];
            [MagicalRecord cleanUp];
            _applicationStarted = NO;
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
    
    BOOL protectedDataAvailable = _applicationStarted = [application isProtectedDataAvailable];
    
    NSLog(@"Protected data is available? %d", protectedDataAvailable);
    
    if (protectedDataAvailable) {
        // do a canary save
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
            Canary *canary = [Canary MR_findFirstInContext:localContext];
            if (!canary) {
                canary = [Canary MR_createEntityInContext:localContext];
            }
            canary.launchDate = [NSDate date];
        } completion:^(BOOL contextDidSave, NSError * _Nullable error) {
            // error should be null and contextDidSave should be true
            if (contextDidSave && error == NULL) {
                if(self.splashView != nil) {
                    [self.splashView.view removeFromSuperview];
                    self.splashView = nil;
                }
                
                [self processOfflineMapArchives];
            } else {
                NSLog(@"Could not read or write from the database");
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"iOS Data Unavailable"
                                                                               message:@"It appears the app data was unavailable when the app became active.  If this continues, please notify your administrator."
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
            enum SFGeometryType geometryType = [featureDao getGeometryType];
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

#pragma mark - SSZipArchiveDelegate methods
- (void) zipArchiveDidUnzipArchiveAtPath:(NSString *)path zipInfo:(unz_global_info)zipInfo unzippedPath:(NSString *)unzippedPath {
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
        }
    }
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

-(BOOL) importGeoPackageFile: (NSString *) path {
    // Import the GeoPackage file
    BOOL imported = false;
    GPKGGeoPackageManager * manager = [GPKGGeoPackageFactory getManager];
    @try {
        imported = [manager importGeoPackageFromPath:path andOverride:true andMove:true];
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

-(BOOL) importGeoPackageFileAsLink: (NSString *) path andMove: (BOOL) moveFile withLayerId: (NSString *) remoteId {
    // Import the GeoPackage file
    BOOL imported = false;
    GPKGGeoPackageManager * manager = [GPKGGeoPackageFactory getManager];
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
                layer.loaded = [NSNumber numberWithBool:NO];
                layer.downloading = NO;
            }
        }];
    } else {
        NSLog(@"GeoPackage file %@ has been imported", path);
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
            NSArray<Layer *> *layers = [Layer MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"remoteId == %@", remoteId] inContext:localContext];
            for (Layer *layer in layers) {
                layer.loaded = [NSNumber numberWithBool:YES];
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

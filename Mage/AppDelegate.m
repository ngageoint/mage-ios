//
//  AppDelegate.m
//  Mage
//
//

#import "AppDelegate.h"
#import <Mage.h>
#import <User.h>
#import <GeoPoint.h>
#import <CoreLocation/CoreLocation.h>
#import <FICImageCache.h>
#import <UserUtility.h>
#import "Attachment+FICAttachment.h"
#import "Attachment+helper.h"

#import "MageInitialViewController.h"
#import "LoginViewController.h"

#import "ZipFile+OfflineMap.h"
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import <HttpManager.h>

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

@interface AppDelegate ()
@property (nonatomic, strong) NSManagedObjectContext *pushManagedObjectContext;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[AFNetworkActivityIndicatorManager sharedManager] setEnabled:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tokenDidExpire:) name: MAGETokenExpiredNotification object:nil];
    NSURL *sdkPreferencesFile = [[NSBundle mainBundle] URLForResource:@"MageSDK.bundle/preferences" withExtension:@"plist"];
    NSDictionary *sdkPreferences = [NSDictionary dictionaryWithContentsOfURL:sdkPreferencesFile];
    
    NSURL *defaultPreferencesFile = [[NSBundle mainBundle] URLForResource:@"preferences" withExtension:@"plist"];
    NSDictionary *defaultPreferences = [NSDictionary dictionaryWithContentsOfURL:defaultPreferencesFile];
    
    NSMutableDictionary *allPreferences = [[NSMutableDictionary alloc] initWithDictionary:sdkPreferences];
    [allPreferences addEntriesFromDictionary:defaultPreferences];
    [[NSUserDefaults standardUserDefaults]  registerDefaults:allPreferences];
    
    FICImageFormat *thumbnailImageFormat = [[FICImageFormat alloc] init];
    thumbnailImageFormat.name = AttachmentSmallSquare;
    thumbnailImageFormat.family = AttachmentFamily;
    thumbnailImageFormat.style = FICImageFormatStyle32BitBGRA;
    thumbnailImageFormat.imageSize = AttachmentSquareImageSize;
    thumbnailImageFormat.maximumCount = 250;
    thumbnailImageFormat.devices = FICImageFormatDevicePhone;
    thumbnailImageFormat.protectionMode = FICImageFormatProtectionModeNone;
    
    FICImageFormat *ipadThumbnailImageFormat = [[FICImageFormat alloc] init];
    ipadThumbnailImageFormat.name = AttachmentMediumSquare;
    ipadThumbnailImageFormat.family = AttachmentFamily;
    ipadThumbnailImageFormat.style = FICImageFormatStyle32BitBGRA;
    ipadThumbnailImageFormat.imageSize = AttachmentiPadSquareImageSize;
    ipadThumbnailImageFormat.maximumCount = 250;
    ipadThumbnailImageFormat.devices = FICImageFormatDevicePhone | FICImageFormatDevicePad;
    ipadThumbnailImageFormat.protectionMode = FICImageFormatProtectionModeNone;
    
    NSArray *imageFormats = @[thumbnailImageFormat, ipadThumbnailImageFormat];
    
    _imageCache = [FICImageCache sharedImageCache];
    _imageCache.delegate = self;
    _imageCache.formats = imageFormats;
    
    [MagicalRecord setupMageCoreDataStack];
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelVerbose];
	 
	return YES;
}

- (void) applicationWillResignActive:(UIApplication *) application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    NSLog(@"applicationWillResignActive");
}

- (void) applicationDidEnterBackground:(UIApplication *) application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    NSLog(@"applicationDidEnterBackground");
    
    [[Mage singleton] stopServices];
}

- (void) applicationWillEnterForeground:(UIApplication *) application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"applicationWillEnterForeground");
    if (![[UserUtility singleton] isTokenExpired]) {
        [[Mage singleton] startServices];
    }
}

- (void) applicationDidBecomeActive:(UIApplication *) application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSLog(@"applicationDidBecomeActive");

    [self processOfflineMapArchives];
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
            if ([selectedCaches containsObject:cacheName]) {
                [cacheOverlay setEnabled:true];
            }
            
            // Check the child caches
            for (CacheOverlay * childCache in [cacheOverlay getChildren]) {
                if (cacheOverlay.enabled || [selectedCaches containsObject:[childCache getCacheName]]) {
                    [childCache setEnabled:true];
                    [cacheOverlay setEnabled:true];
                }
            }
        }
    }
    
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
        GeoPackageCacheOverlay * cacheOverlay = [self getGeoPackageCacheOverlayWithManager:manager andName:geoPackage];
        if(cacheOverlay != nil){
            [cacheOverlays addObject:cacheOverlay];
        }
    }
}

-(GeoPackageCacheOverlay *) getGeoPackageCacheOverlayWithManager: (GPKGGeoPackageManager *) manager andName: (NSString *) name{
    
    GeoPackageCacheOverlay * cacheOverlay = nil;
    
    // Add the GeoPackage overlay
    GPKGGeoPackage * geoPackage = [manager open:name];
    @try {
        NSMutableArray<CacheOverlay *> * tables = [[NSMutableArray alloc] init];
        
        // GeoPackage tile tables
        NSArray * tileTables = [geoPackage getTileTables];
        for(NSString * tileTable in tileTables){
            NSString * tableCacheName = [CacheOverlay buildChildCacheNameWithName:name andChildName:tileTable];
            GPKGTileDao * tileDao = [geoPackage getTileDaoWithTableName:tileTable];
            int count = [tileDao count];
            int minZoom = tileDao.minZoom;
            int maxZoom = tileDao.maxZoom;
            GeoPackageTableCacheOverlay * tableCache = [[GeoPackageTileTableCacheOverlay alloc] initWithName:tileTable andGeoPackage:name andCacheName:tableCacheName andCount:count andMinZoom:minZoom andMaxZoom:maxZoom];
            [tables addObject:tableCache];
        }
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
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
            GeoPackageTableCacheOverlay * tableCache = [[GeoPackageFeatureTableCacheOverlay alloc] initWithName:featureTable andGeoPackage:name andCacheName:tableCacheName andCount:count andMinZoom:minZoom andIndexed:indexed andGeometryType:geometryType];
            [tables addObject:tableCache];
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
    ZipFile *zipFile = [[ZipFile alloc] initWithFileName:archivePath mode:ZipFileModeUnzip];
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
    [[LocationFetchService singleton] stop];
    [[ObservationFetchService singleton] stop];
    [[ObservationPushService singleton] stop];
    [[AttachmentPushService singleton] stop];
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

- (void)imageCache:(FICImageCache *)imageCache wantsSourceImageForEntity:(id<FICEntity>)entity withFormatName:(NSString *)formatName completionBlock:(FICImageRequestCompletionBlock)completionBlock {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // Fetch the desired source image by making a network request
        Attachment *attachment = (Attachment *)entity;
        UIImage *sourceImage = nil;
        NSLog(@"content type %@", attachment.contentType);
        if ([attachment.contentType hasPrefix:@"image"]) {
            sourceImage = [UIImage imageWithData:[NSData dataWithContentsOfURL:[attachment sourceURL]]];
        } else if ([attachment.contentType hasPrefix:@"video"] || [attachment.contentType hasPrefix:@"audio"]) {
            sourceImage = [UIImage imageNamed:@"play_circle"];
        } else {
            sourceImage = [UIImage imageNamed:@"paperclip"];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(sourceImage);
        });
    });
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

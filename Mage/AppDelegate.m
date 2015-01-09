//
//  AppDelegate.m
//  Mage
//
//  Created by Dan Barela on 2/13/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "AppDelegate.h"
#import <User.h>
#import <GeoPoint.h>
#import <CoreLocation/CoreLocation.h>
#import <FICImageCache.h>
#import <UserUtility.h>
#import "Attachment+FICAttachment.h"

#import "MageInitialViewController.h"

#import "ZipFile+OfflineMap.h"

@interface AppDelegate ()
@property (nonatomic, strong) NSManagedObjectContext *pushManagedObjectContext;
@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

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
    thumbnailImageFormat.style = FICImageFormatStyle16BitBGR;
    thumbnailImageFormat.imageSize = AttachmentSquareImageSize;
    thumbnailImageFormat.maximumCount = 250;
    thumbnailImageFormat.devices = FICImageFormatDevicePhone | FICImageFormatDevicePad;
    thumbnailImageFormat.protectionMode = FICImageFormatProtectionModeNone;
    
    FICImageFormat *largeImageFormat = [[FICImageFormat alloc] init];
    largeImageFormat.name = AttachmentLarge;
    largeImageFormat.family = AttachmentFamily;
    largeImageFormat.style = FICImageFormatStyle32BitBGRA;
    largeImageFormat.imageSize = [[UIScreen mainScreen] bounds].size;
    largeImageFormat.maximumCount = 250;
    largeImageFormat.devices = FICImageFormatDevicePhone | FICImageFormatDevicePad;
    largeImageFormat.protectionMode = FICImageFormatProtectionModeNone;
    
    NSArray *imageFormats = @[thumbnailImageFormat, largeImageFormat];
    
    _imageCache = [FICImageCache sharedImageCache];
    _imageCache.delegate = self;
    _imageCache.formats = imageFormats;
    
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:@"Mage.sqlite"];
    
    _locationFetchService = [[LocationFetchService alloc] init];
    _observationFetchService = [[ObservationFetchService alloc] init];
    
    _observationPushService = [[ObservationPushService alloc] init];
    _attachmentPushService = [[AttachmentPushService alloc] init];
	 
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
    
    [self.locationFetchService stop];
}

- (void) applicationWillEnterForeground:(UIApplication *) application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"applicationWillEnterForeground");
    if (![UserUtility isTokenExpired]) {
        [self.locationFetchService start];
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
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *offlineMaps = [NSMutableDictionary dictionaryWithDictionary:[defaults dictionaryForKey:@"offlineMaps"]];
    [offlineMaps setObject:archives forKey:@"processing"];
    [defaults setObject:offlineMaps forKey:@"offlineMaps"];
    [defaults synchronize];
    
    for (id archive in archives) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(void) {
            [self processArchiveAtFilePath:[NSString stringWithFormat:@"%@/%@", documentsDirectory, archive] toDirectory:[documentsDirectory stringByAppendingPathComponent:@"MapCache"]];
        });
    }
}

- (void) processArchiveAtFilePath:(NSString *) archivePath toDirectory:(NSString *) directory {
    NSLog(@"File %@", archivePath);
    
    NSError *error = nil;
    ZipFile *zipFile = [[ZipFile alloc] initWithFileName:archivePath mode:ZipFileModeUnzip];
    NSArray *caches = [zipFile expandToPath:directory error:&error];
    if (error) {
        NSLog(@"Error extracting offline map archive. %@", error);
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *offlineMaps = [[defaults dictionaryForKey:@"offlineMaps"] mutableCopy];
        
    if (caches.count) {
        NSMutableSet *availableCaches =  [[NSMutableSet alloc] initWithArray:[offlineMaps objectForKey:@"available"]];
        [availableCaches addObjectsFromArray:caches];
        [offlineMaps setValue:[availableCaches allObjects] forKey:@"available"];
    }
    
    NSMutableArray *archiveFileNames = [[offlineMaps objectForKey:@"processing"] mutableCopy];
    [archiveFileNames removeObject:[archivePath lastPathComponent]];
    [offlineMaps setValue:archiveFileNames forKey:@"processing"];
    
    [defaults setValue:offlineMaps forKeyPath:@"offlineMaps"];
    [defaults synchronize];
}

- (void) applicationWillTerminate:(UIApplication *) application {
    NSLog(@"applicationWillTerminate");

    [MagicalRecord cleanUp];
}

-(LocationService *) locationService {
    if (_locationService == nil) {
        _locationService = [[LocationService alloc] init];
    }
    
    return _locationService;
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
        NSURL *requestURL = [entity sourceImageURLWithFormatName:formatName];
        NSLog(@"content type %@", attachment.contentType);
        if ([attachment.contentType hasPrefix:@"image"]) {
            
            if (attachment.localPath != nil) {
                NSData *data = [NSData dataWithContentsOfFile:attachment.localPath];
                sourceImage = [UIImage imageWithData:data];
            } else {
                NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
                NSString *tokenUrl = [NSString stringWithFormat:@"%@?access_token=%@", requestURL, [defaults valueForKeyPath:@"loginParameters.token"]];
                NSLog(@"token url %@", tokenUrl);
                NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:tokenUrl]];
                sourceImage = [UIImage imageWithData:data];
            }
        } else if ([attachment.contentType hasPrefix:@"video"]) {
            sourceImage = [UIImage imageNamed:@"video"];
        } else {
            sourceImage = [UIImage imageNamed:@"download"];
        }

        dispatch_async(dispatch_get_main_queue(), ^{
            completionBlock(sourceImage);
        });
    });
}

@end

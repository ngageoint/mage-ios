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
#import "CoreDataStack.h"
#import "NSManagedObjectContext+MAGE.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{

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
    thumbnailImageFormat.devices = FICImageFormatDevicePhone;
    thumbnailImageFormat.protectionMode = FICImageFormatProtectionModeNone;
    
    FICImageFormat *largeImageFormat = [[FICImageFormat alloc] init];
    largeImageFormat.name = AttachmentLarge;
    largeImageFormat.family = AttachmentFamily;
    largeImageFormat.style = FICImageFormatStyle32BitBGRA;
    largeImageFormat.imageSize = [[UIScreen mainScreen] bounds].size;
    largeImageFormat.maximumCount = 250;
    largeImageFormat.devices = FICImageFormatDevicePhone;
    largeImageFormat.protectionMode = FICImageFormatProtectionModeNone;
    
    NSArray *imageFormats = @[thumbnailImageFormat, largeImageFormat];
    
    _imageCache = [FICImageCache sharedImageCache];
    _imageCache.delegate = self;
    _imageCache.formats = imageFormats;
    
    [CoreDataStack setupCoreDataStack];
    
    _locationFetchService = [[LocationFetchService alloc] init];
    _observationFetchService = [[ObservationFetchService alloc] init];
    _observationPushService = [[ObservationPushService alloc] init];
	 
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
    
    [_locationFetchService stop];
}

- (void) applicationWillEnterForeground:(UIApplication *) application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    NSLog(@"applicationWillEnterForeground");
    if (![UserUtility isTokenExpired]) {
        [_locationFetchService start];
    }
}

- (void) applicationDidBecomeActive:(UIApplication *) application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    NSLog(@"applicationDidBecomeActive");

}

- (void) applicationWillTerminate:(UIApplication *) application {
    NSLog(@"applicationWillTerminate");

    // Saves changes in the application's managed object context before the application terminates.
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = [NSManagedObjectContext defaultManagedObjectContext];
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
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
        if ([attachment.contentType hasPrefix:@"image"]) {
            
            NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
            NSString *tokenUrl = [NSString stringWithFormat:@"%@?access_token=%@", requestURL, [defaults objectForKey:@"token"]];
            NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:tokenUrl]];
            sourceImage = [UIImage imageWithData:data];
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

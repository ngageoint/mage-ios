//
//  AppDelegate.h
//  Mage
//
//  Created by Dan Barela on 2/13/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FICImageCache.h>
#import <LocationFetchService.h>
#import <ObservationFetchService.h>


@interface AppDelegate : UIResponder <UIApplicationDelegate, FICImageCacheDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) FICImageCache *imageCache;
@property (readonly, strong, nonatomic) LocationFetchService *locationFetchService;
@property (readonly, strong, nonatomic) ObservationFetchService *observationFetchService;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end

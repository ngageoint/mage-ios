//
//  AppDelegate.h
//  Mage
//
//  Created by Dan Barela on 2/13/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FICImageCache.h>
#import <LocationService.h>
#import <LocationFetchService.h>
#import <ObservationFetchService.h>
#import <ObservationPushService.h>
#import <AttachmentPushService.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, FICImageCacheDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) FICImageCache *imageCache;

- (NSURL *)applicationDocumentsDirectory;

@end

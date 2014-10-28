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

@interface AppDelegate : UIResponder <UIApplicationDelegate, FICImageCacheDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) FICImageCache *imageCache;
@property (strong, nonatomic) LocationService *locationService;
@property (strong, nonatomic) LocationFetchService *locationFetchService;
@property (strong, nonatomic) ObservationFetchService *observationFetchService;

- (NSURL *)applicationDocumentsDirectory;

@end

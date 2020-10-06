//
//  TestingAppDelegate.m
//  MAGE
//
//  Created by Dan Barela on 2/5/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "TestingAppDelegate.h"
#import "MagicalRecord+MAGE.h"

@implementation TestingAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
//    [application setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];
//    
//    NSURL *sdkPreferencesFile = [[NSBundle mainBundle] URLForResource:@"MageSDK.bundle/preferences" withExtension:@"plist"];
//    NSDictionary *sdkPreferences = [NSDictionary dictionaryWithContentsOfURL:sdkPreferencesFile];
//    
//    NSURL *defaultPreferencesFile = [[NSBundle mainBundle] URLForResource:@"preferences" withExtension:@"plist"];
//    NSDictionary *defaultPreferences = [NSDictionary dictionaryWithContentsOfURL:defaultPreferencesFile];
//    
//    NSMutableDictionary *allPreferences = [[NSMutableDictionary alloc] initWithDictionary:sdkPreferences];
//    [allPreferences addEntriesFromDictionary:defaultPreferences];
//    [[NSUserDefaults standardUserDefaults]  registerDefaults:allPreferences];
//    
//    [MagicalRecord setupMageCoreDataStack];
//    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelVerbose];
    
    return YES;
}

- (void) logout {
    self.logoutCalled = YES;
}

@end

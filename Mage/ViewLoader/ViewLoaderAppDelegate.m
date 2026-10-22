//
//  ViewLoaderAppDelegate.m
//  MAGE
//
//  Created by Daniel Barela on 6/11/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ViewLoaderAppDelegate.h"
#import "MAGE-Swift.h"

@implementation ViewLoaderAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions {
    return true;
}

- (void) sceneDidConnectWithWindow:(UIWindow *)window {
    self.window = window;
    [self.window makeKeyAndVisible];
    self.window.backgroundColor = [UIColor blackColor];
    self.window.rootViewController = [ViewLoader createRootViewController];
}
@end

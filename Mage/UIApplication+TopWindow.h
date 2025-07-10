//
//  UIApplication+TopWindow.h
//  MAGE
//
//  Created by Brent Michalski on 7/10/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//


#import <UIKit/UIKit.h>

@interface UIApplication (TopWindow)

/// Safely gets the key window in a multi-scene environment (iOS 13+ safe)
- (UIWindow *)activeKeyWindow;

/// Convenience getter for rootViewController of activeKeyWindow
- (UIViewController *)activeRootViewController;

@end

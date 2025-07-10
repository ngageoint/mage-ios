//
//  UIApplication+TopWindow.m
//  MAGE
//
//  Created by Brent Michalski on 7/10/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import "UIApplication+TopWindow.h"

@implementation UIApplication (TopWindow)

- (UIWindow *)activeKeyWindow {
    for (UIScene *scene in self.connectedScenes) {
        if ([scene isKindOfClass:[UIWindowScene class]] &&
            scene.activationState == UISceneActivationStateForegroundActive) {
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow) {
                    return window;
                }
            }
        }
    }
    return nil;
}

- (UIViewController *)activeRootViewController {
    return [self activeKeyWindow].rootViewController;
}

@end

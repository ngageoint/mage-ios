//
//  UIViewController.m
//  MAGE
//
//  Created by Brent Michalski on 7/15/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//


#import "UIViewController+TopMost.h"

@implementation UIViewController (TopMost)

+ (UIViewController *)topMostViewController {
    UIWindow *keyWindow = nil;

    for (UIWindowScene *scene in UIApplication.sharedApplication.connectedScenes) {
        if (scene.activationState == UISceneActivationStateForegroundActive &&
            [scene isKindOfClass:[UIWindowScene class]]) {
            for (UIWindow *window in scene.windows) {
                if (window.isKeyWindow) {
                    keyWindow = window;
                    break;
                }
            }
        }
        if (keyWindow) break;
    }

    UIViewController *rootViewController = keyWindow.rootViewController;
    return [self _topViewControllerFrom:rootViewController];
}

+ (UIViewController *)_topViewControllerFrom:(UIViewController *)vc {
    if ([vc isKindOfClass:[UINavigationController class]]) {
        return [self _topViewControllerFrom:((UINavigationController *)vc).visibleViewController];
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        return [self _topViewControllerFrom:((UITabBarController *)vc).selectedViewController];
    } else if (vc.presentedViewController) {
        return [self _topViewControllerFrom:vc.presentedViewController];
    } else {
        return vc;
    }
}

@end

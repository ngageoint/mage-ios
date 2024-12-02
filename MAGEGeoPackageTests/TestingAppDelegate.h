//
//  TestingAppDelegate.h
//  MAGE
//
//  Created by Dan Barela on 10/31/24.
//  Copyright © 2024 National Geospatial Intelligence Agency. All rights reserved.
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@class BaseMapOverlay;

@interface TestingAppDelegate : AppDelegate
@property (nonatomic, strong) UIWindow *window;
@property (nonatomic) BOOL logoutCalled;

- (void) logout;
- (BaseMapOverlay *) getBaseMap;
- (BaseMapOverlay *) getDarkBaseMap;
@end
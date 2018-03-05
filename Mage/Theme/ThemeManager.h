//
//  ThemeManager.h
//  MAGE
//
//  Created by Dan Barela on 3/2/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kThemeChangedKey;

typedef NS_ENUM(NSInteger, MageTheme) {
    Day,
    Night
};

#define TheCurrentTheme [[ThemeManager sharedManager] currentTheme]

@interface ThemeManager : NSObject

+ (instancetype) sharedManager;

@property (nonatomic, strong) NSNumber *forcedTheme;
@property (nonatomic, readonly) MageTheme currentTheme;

@end

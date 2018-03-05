//
//  ThemeManager.m
//  MAGE
//
//  Created by Dan Barela on 3/2/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ThemeManager.h"

#define BRIGHTNESS_DARK_THRESHOLD 0.30
#define BRIGHTNESS_LIGHT_THRESHOLD 0.40

static NSString *const kForcedThemeKey = @"forcedTheme";
NSString *const kThemeChangedKey = @"themeChanged";

@interface ThemeManager ()

@property (nonatomic, readwrite) MageTheme currentTheme;

@end

@implementation ThemeManager

+ (instancetype) sharedManager {
    static ThemeManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (instancetype) init {
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appDidBecomeActive)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(brightnessDidChange:)
                                                     name:UIScreenBrightnessDidChangeNotification
                                                   object:nil];

    }
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) setCurrentTheme:(MageTheme)currentTheme {
    [self setCurrentTheme:currentTheme animated:YES];
}

- (void) setCurrentTheme:(MageTheme)currentTheme animated: (BOOL) animated {
    if (_currentTheme != currentTheme) {
        _currentTheme = currentTheme;
        [UIView animateWithDuration:animated ? 0.5 : 0.0
                              delay:0
             usingSpringWithDamping:1
              initialSpringVelocity:0
                            options:0
                         animations:^{
                             [[NSNotificationCenter defaultCenter] postNotificationName:kThemeChangedKey
                                                                                 object:@(currentTheme)];
                         }
                         completion:nil];
    }
}

- (void)setForcedTheme:(NSNumber *)forcedTheme {
    [[NSUserDefaults standardUserDefaults] setObject:forcedTheme forKey:kForcedThemeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.currentTheme = [self calculateCurrentTheme];
}

- (NSNumber *)forcedTheme {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kForcedThemeKey];
}

#pragma mark - Calculations

- (MageTheme) calculateCurrentTheme {
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(brightnessDidChange:) object:nil];
    [self performSelector:@selector(brightnessDidChange:) withObject:nil afterDelay:10];
    return (MageTheme)ABS(1 - self.currentTheme);
    
//    if (self.forcedTheme != nil) {
//        return [self.forcedTheme integerValue];
//    }
//
//    CGFloat brightness = [[UIScreen mainScreen] brightness];
//
//    if (self.currentTheme == Day) {
//        if (brightness <= BRIGHTNESS_DARK_THRESHOLD) {
//            return Night;
//        }
//        return Day;
//    } else {
//        if (brightness >= BRIGHTNESS_LIGHT_THRESHOLD) {
//            return Day;
//        }
//        return Night;
//    }
}

- (void)brightnessDidChange:(NSNotification *)notification {
    UIApplicationState state = [[UIApplication sharedApplication] applicationState];
    if (state != UIApplicationStateActive && state != UIApplicationStateInactive) {
        return;
    }
    self.currentTheme = [self calculateCurrentTheme];
}

- (void)appDidBecomeActive {
    self.currentTheme = [self calculateCurrentTheme];
}

@end

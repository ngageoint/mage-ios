//
//  ThemeManager.m
//  MAGE
//
//  Created by Dan Barela on 3/2/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ThemeManager.h"
#import "DarkTheme.h"
#import "DayTheme.h"
#import "AutoSunriseSunsetTheme.h"
#import "Theme.h"

NSString *const kThemeKey = @"theme";
NSString *const kThemeChangedKey = @"themeChanged";
NSInteger const NUM_THEMES = 3;

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
        id<Theme> themeDefintion = [[ThemeManager sharedManager] themeDefinitionForTheme:currentTheme];
        [UITextField appearance].keyboardAppearance = themeDefintion.keyboardAppearance;
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

- (id<Theme>) curentThemeDefinition {
    return [self themeDefinitionForTheme:[[self theme] integerValue]];
}

- (id<Theme>) themeDefinitionForTheme:(MageTheme)theme {
    switch(theme) {
        case Night:
            return [DarkTheme sharedInstance];
        case Day:
            return [DayTheme sharedInstance];
        case AutoSunriseSunset:
            return [AutoSunriseSunsetTheme sharedInstance];
    }
    return [DayTheme sharedInstance];
}

- (void)setTheme:(NSNumber *)theme {
    [[NSUserDefaults standardUserDefaults] setObject:theme forKey:kThemeKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.currentTheme = [self calculateCurrentTheme];
}

- (NSNumber *)theme {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kThemeKey];
}

#pragma mark - Calculations

- (MageTheme) calculateCurrentTheme {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    return [[defaults objectForKey:kThemeKey] integerValue];
}

- (void)appDidBecomeActive {
    self.currentTheme = [self calculateCurrentTheme];
}

@end

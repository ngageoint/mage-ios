//
//  AutoSunriseSunset.m
//  MAGE
//
//  Created by Dan Barela on 3/28/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "AutoSunriseSunsetTheme.h"
#import "DarkTheme.h"
#import "DayTheme.h"
#import <EDSunriseSet/EDSunriseSet.h>
#import "LocationService.h"
#import <CoreLocation/CoreLocation.h>

@interface AutoSunriseSunsetTheme ()

@property (strong, nonatomic) NSDate *themeChangeTime;
@property (nonatomic) BOOL daytime;

@end

@implementation AutoSunriseSunsetTheme

+ (instancetype) sharedInstance {
    static AutoSunriseSunsetTheme *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

- (NSDate *) themeChangeTime {
    // if the current date is before the theme change time
    if (_themeChangeTime && [[NSDate new] compare:_themeChangeTime] == NSOrderedAscending) {
        return _themeChangeTime;
    }
    
    CLLocation *location = [[LocationService singleton] location];
    
    if (location) {
        EDSunriseSet *sunriseSunset = [[EDSunriseSet alloc] initWithTimezone:[NSTimeZone systemTimeZone] latitude:location.coordinate.latitude longitude:location.coordinate.longitude];
        [sunriseSunset calculate:[NSDate new]];
        // if the current date is less than sunrise
        if ([[NSDate new] compare:sunriseSunset.sunrise] == NSOrderedAscending) {
            _themeChangeTime = sunriseSunset.sunrise;
            self.daytime = NO;
            return _themeChangeTime;
        } else if ([[NSDate new] compare:sunriseSunset.sunset] == NSOrderedAscending) {
            _themeChangeTime = sunriseSunset.sunset;
            self.daytime = YES;
            return _themeChangeTime;
        } else {
            // must be the next day at sunrise
            NSDate *tomorrow = [[NSDate new] dateByAddingDays:1];
            [sunriseSunset calculate:tomorrow];
            _themeChangeTime = sunriseSunset.sunrise;
            self.daytime = NO;
            return _themeChangeTime;
        }
    } else {
        // since no location is available, just use 6am and 6pm for sunrise and sunset
        NSDateComponents *comps = [[NSDateComponents alloc] init];
        [comps setHour:6];
        
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDate *sunriseDateEstimate = [calendar dateFromComponents:comps];
        
        [comps setHour:18];
        NSDate *sunsetDateEstimate = [calendar dateFromComponents:comps];
        // if the current date is less than sunrise
        if ([[NSDate new] compare:sunriseDateEstimate] == NSOrderedAscending) {
            _themeChangeTime = sunriseDateEstimate;
            self.daytime = NO;
            return _themeChangeTime;
        } else if ([[NSDate new] compare:sunsetDateEstimate] == NSOrderedAscending) {
            _themeChangeTime = sunsetDateEstimate;
            self.daytime = YES;
            return _themeChangeTime;
        } else {
            // must be the next day at sunrise
            _themeChangeTime = sunriseDateEstimate;
            self.daytime = NO;
            return _themeChangeTime;
        }
        
    }
}

- (NSString *) displayName {
    return @"Auto (Sunrise/Sunset)";
}

- (id<Theme>) autoTheme {
    [self themeChangeTime];
    if (self.daytime) {
        return [DayTheme sharedInstance];
    }
    return [DarkTheme sharedInstance];
}

- (UIColor *) primaryText {
    return [[self autoTheme] primaryText];
}

- (UIColor *) secondaryText {
    return [[self autoTheme] secondaryText];
}

- (UIColor *) background {
    return [[self autoTheme] background];
}

- (UIColor *) tableBackground {
    return [[self autoTheme] tableBackground];
}

- (UIColor *) tableSeparator {
    return [[self autoTheme] tableSeparator];
}

- (UIColor *) tableCellDisclosure {
    return [[self autoTheme] tableCellDisclosure];
}

- (UIColor *) dialog {
    return [[self autoTheme] dialog];
}

- (UIColor *) primary {
    return [[self autoTheme] primary];
}

- (UIColor *) secondary {
    return [[self autoTheme] secondary];
}

- (UIColor *) brand {
    return [[self autoTheme] brand];
}

- (UIColor *) themedButton {
    return [[self autoTheme] themedButton];
}

- (UIColor *) flatButton {
    return [[self autoTheme] flatButton];
}
    
- (UIColor *) brightButton {
    return [[self autoTheme] brightButton];
}
    
- (UIColor *) themedWhite {
    return [[self autoTheme] themedWhite];
}
    
- (UIColor *) inactiveIcon {
    return [[self autoTheme] inactiveIcon];
}

- (UIColor *) inactiveIconWithColor: (UIColor *) color {
    return [[self autoTheme] inactiveIconWithColor:color];

}

- (UIColor *) activeIcon {
    return [[self autoTheme] activeIcon];
}

- (UIColor *) activeIconWithColor: (UIColor *) color {
    return [[self autoTheme] activeIconWithColor:color];
}

- (UIColor *) activeTabIcon {
    return [[self autoTheme] activeTabIcon];
}

- (UIColor *) inactiveTabIcon {
    return [[self autoTheme] inactiveTabIcon];
}

- (UIColor *) tabBarTint {
    return [[self autoTheme] tabBarTint];
}

- (UIColor *) navBarPrimaryText {
    return [[self autoTheme] navBarPrimaryText];
}

- (UIColor *) navBarSecondaryText {
    return [[self autoTheme] navBarSecondaryText];
}

- (BOOL) darkMap {
    return [[self autoTheme] darkMap];
}

- (UIKeyboardAppearance) keyboardAppearance {
    return [[self autoTheme] keyboardAppearance];
}

@end

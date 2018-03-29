//
//  Theme.h
//  MAGE
//
//  Created by Dan Barela on 3/27/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol Theme <NSObject>

@required
+ (instancetype) sharedInstance;
- (NSString *) displayName;
- (UIColor *) primaryText;
- (UIColor *) secondaryText;
- (UIColor *) background;
- (UIColor *) tableBackground;
- (UIColor *) dialog;
- (UIColor *) primary;
- (UIColor *) secondary;
- (UIColor *) brand;
- (UIColor *) themedWhite;
- (UIColor *) themedButton;
- (UIColor *) brightButton;
- (UIColor *) flatButton;
- (UIColor *) inactiveIcon;
- (UIColor *) inactiveIconWithColor: (UIColor *) color;
- (UIColor *) activeIcon;
- (UIColor *) activeIconWithColor: (UIColor *) color;
- (UIColor *) activeTabIcon;
- (UIColor *) inactiveTabIcon;
- (UIColor *) tabBarTint;
- (UIColor *) navBarPrimaryText;
- (UIColor *) navBarSecondaryText;
- (BOOL) darkMap;
- (UIKeyboardAppearance) keyboardAppearance;

@end

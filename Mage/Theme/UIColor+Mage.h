//
//  UIColor+Theme.h
//  MAGE
//
//  Created by Dan Barela on 3/2/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface UIColor (Mage)

+ (UIColor * _Nonnull) mageBlue;
+ (UIColor * _Nonnull) primaryText;
+ (UIColor * _Nonnull) secondaryText;
+ (UIColor * _Nonnull) background;
+ (UIColor * _Nonnull) tableBackground;
+ (UIColor * _Nonnull) tableSeparator;
+ (UIColor * _Nonnull) tableCellDisclosure;
+ (UIColor * _Nonnull) dialog;
+ (UIColor * _Nonnull) brand;
+ (UIColor * _Nonnull) primary;
+ (UIColor * _Nonnull) secondary;
+ (UIColor * _Nonnull) themedButton;
+ (UIColor * _Nonnull) themedWhite;
+ (UIColor * _Nonnull) flatButton;
+ (UIColor * _Nonnull) brightButton;
+ (UIColor * _Nonnull) inactiveIcon;
+ (UIColor * _Nonnull) inactiveIconWithColor: (UIColor * _Nonnull) color;
+ (UIColor * _Nonnull) activeIcon;
+ (UIColor * _Nonnull) activeIconWithColor: (UIColor * _Nonnull) color;
+ (UIColor * _Nonnull) activeTabIcon;
+ (UIColor * _Nonnull) inactiveTabIcon;
+ (UIColor * _Nonnull) tabBarTint;
+ (UIColor * _Nonnull) navBarPrimaryText;
+ (UIColor * _Nonnull) navBarSecondaryText;
+ (void) themeMap: (MKMapView * _Nonnull) map;
+ (BOOL) darkMap;
+ (UIKeyboardAppearance) keyboardAppearance;

@end

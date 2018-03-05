//
//  Theme+UIResponder.h
//  MAGE
//
//  Created by Dan Barela on 3/2/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ThemeManager.h"
#import "UIColor+Mage.h"

@protocol UIResponderTheme <NSObject>

- (void) themeDidChange: (MageTheme) theme;

@end


@interface UIResponder (Theme) <UIResponderTheme>

- (void) registerForThemeChanges;

@end

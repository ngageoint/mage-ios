//
//  Theme+UIResponder.h
//  MAGE
//
//  Created by Dan Barela on 3/2/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ThemeManager.h"
#import "UIColor+Mage.h"
#import <MaterialComponents/MaterialContainerScheme.h>

@protocol UIResponderTheme <NSObject>

- (void) themeDidChange: (MageTheme) theme;

@end


@interface UIResponder (Theme) <UIResponderTheme>
//@property (nonatomic, strong) id<MDCContainerScheming> scheme;

- (void) registerForThemeChanges;
//- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>) containerScheme;

@end

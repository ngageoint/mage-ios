//
//  OrView.h
//  MAGE
//
//  Created by Dan Barela on 5/2/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppContainerScheming.h"

@interface OrView : UIStackView

- (void) applyThemeWithScheme:(id<AppContainerScheming>)containerScheme;

@end

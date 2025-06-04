//
//  OrView.h
//  MAGE
//
//  Created by Dan Barela on 5/2/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AuthenticationTheming.h"

@interface OrView: UIStackView

- (void) applyTheme:(id<AuthenticationTheming>)theme;

@end

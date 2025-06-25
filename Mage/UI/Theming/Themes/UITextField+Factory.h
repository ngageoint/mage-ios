//
//  UITextField+Factory.h
//  MAGE
//
//  Created by Brent Michalski on 6/25/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MAGE-Swift.h"

@interface UITextField (Factory)

+ (UITextField *)themedTextFieldWithPlaceholder:(NSString *)placeholder
                                          scheme:(id<AppContainerScheming>)scheme
                                         target:(id)target
                                         action:(SEL)selector;

@end

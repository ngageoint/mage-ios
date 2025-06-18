//
//  FloatingButtonFactory.h
//  MAGE
//
//  Created by Brent Michalski on 6/17/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit/h>
#import "AppContainerScheming.h"

NS_ASSUME_NONNULL_BEGIN

@interface FloatingButtonFactory: NSObject

+ (UIButton *)floatingButtonWithImageName:(nullable NSString *)imageName
                                   scheme:(nullable NSObject<AppContainerScheming> *)scheme
                            useErrorColor:(BOOL)useErrorColor
                                     size:(CGFloat)size
                                   target:(nullable id)target
                                   action:(nullable SEL)action
                                      tag:(NSInteger)tag
                      accessibilityLabel:(nullable NSString *)accessibilityLabel;

+ (UIButton *)floatingButtonWithImageName:(nullable NSString *)imageName
                                   scheme:(nullable NSObject<AppContainerScheming> *)scheme
                                   target:(nullable id)target
                                   action:(nullable SEL)action
                                      tag:(NSInteger)tag
                      accessibilityLabel:(nullable NSString *)accessibilityLabel;

@end

NS_ASSUME_NONNULL_END

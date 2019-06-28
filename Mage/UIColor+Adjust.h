//
//  UIColor+Adjust.h
//  MAGE
//
//  Created by William Newman on 6/25/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (Adjust)

- (UIColor *) lighter:(CGFloat) percentage;
- (UIColor *) darker:(CGFloat) percentage;
- (UIColor *) brightness:(CGFloat) percentage;
    
@end

NS_ASSUME_NONNULL_END

//
//  UIColor+Adjust.m
//  MAGE
//
//  Created by William Newman on 6/25/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import "UIColor+Adjust.h"

@implementation UIColor (Adjust)

- (UIColor *) lighter:(CGFloat) percentage {
    return [self adjustColor:ABS(percentage)];
}

- (UIColor *) darker:(CGFloat) percentage {
    return [self adjustColor:-1 * ABS(percentage)];
}

- (UIColor * ) brightness:(CGFloat) percentage {
    CGFloat brightness = 0;
    if ([self getHue:nil saturation:nil brightness:&brightness alpha:nil]) {
        if (brightness > .5) {
            return [self darker:percentage];
        } else {
            return [self lighter:percentage];
        }
    }
    
    return self;
}

- (UIColor * ) adjustColor:(CGFloat) percentage {
    CGFloat red = 0;
    CGFloat green = 0;
    CGFloat blue = 0;
    CGFloat alpha = 0;
    
    if ([self getRed:&red green:&green blue:&blue alpha:&alpha]) {
        return [UIColor colorWithRed:MIN(red + percentage/100, 1.0) green:MIN(green + percentage/100, 1.0) blue:MIN(blue + percentage/100, 1.0) alpha:alpha];
    } else {
        return nil;
    }
}



@end

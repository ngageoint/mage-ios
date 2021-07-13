//
//  UIColor+Hex.m
//  MAGE
//
//  Created by William Newman on 3/11/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

#import "UIColor+Hex.h"

@implementation UIColor (Hex)

-(NSString *) hex {
    CGColorSpaceModel colorSpace = CGColorSpaceGetModel(CGColorGetColorSpace(self.CGColor));
    const CGFloat *components = CGColorGetComponents(self.CGColor);
    
    CGFloat r, g, b;

    if (colorSpace == kCGColorSpaceModelMonochrome) {
        r = components[0];
        g = components[0];
        b = components[0];
    } else if (colorSpace == kCGColorSpaceModelRGB) {
        r = components[0];
        g = components[1];
        b = components[2];
    } else {
        r = 0.0;
        g = 0.0;
        b = 0.0;
    }

    return [NSString stringWithFormat:@"#%02lX%02lX%02lX",
            lroundf(r * 255),
            lroundf(g * 255),
            lroundf(b * 255)];
}

@end

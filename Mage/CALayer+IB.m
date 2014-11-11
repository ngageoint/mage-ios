//
//  CALayer+IB.m
//  MAGE
//
//  Created by William Newman on 11/11/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "CALayer+IB.h"

@implementation CALayer (IB)

-(void) setBorderUIColor:(UIColor *) color {
    self.borderColor = color.CGColor;
}

-(UIColor *) borderUIColor {
    return [UIColor colorWithCGColor:self.borderColor];
}

-(UIColor *) shadowUIColor {
    return [UIColor colorWithCGColor:self.shadowColor];
}

-(void) setShadowUIColor:(UIColor *) color {
    self.shadowColor = color.CGColor;
}

@end

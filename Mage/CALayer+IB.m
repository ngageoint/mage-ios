//
//  CALayer+IB.m
//  MAGE
//
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

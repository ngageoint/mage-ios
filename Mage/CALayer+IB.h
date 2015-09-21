//
//  CALayer+IB.h
//  MAGE
//
//

#import <QuartzCore/QuartzCore.h>

@interface CALayer (IB)

-(UIColor *) borderUIColor;
-(void) setBorderUIColor:(UIColor *) color;

-(UIColor *) shadowUIColor;
-(void) setShadowUIColor:(UIColor *) color;


@end

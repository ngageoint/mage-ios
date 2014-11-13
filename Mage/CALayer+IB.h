//
//  CALayer+IB.h
//  MAGE
//
//  Created by William Newman on 11/11/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface CALayer (IB)

-(UIColor *) borderUIColor;
-(void) setBorderUIColor:(UIColor *) color;

-(UIColor *) shadowUIColor;
-(void) setShadowUIColor:(UIColor *) color;


@end

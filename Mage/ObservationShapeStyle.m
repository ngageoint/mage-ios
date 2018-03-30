//
//  ObservationShapeStyle.m
//  MAGE
//
//  Created by Brian Osborn on 6/19/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

@import HexColors;

#import "ObservationShapeStyle.h"

@implementation ObservationShapeStyle

-(id) init{
    self = [super init];
    if(self != nil){
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [self setLineWidth:[defaults floatForKey:@"fill_default_line_width"]];
        [self setStrokeColor:[UIColor colorWithHexString:[defaults stringForKey:@"line_default_color"] alpha:[defaults integerForKey:@"line_default_color_alpha"] / 255.0]];
        [self setFillColor:[UIColor colorWithHexString:[defaults stringForKey:@"fill_default_color"] alpha:[defaults integerForKey:@"fill_default_color_alpha"] / 255.0]];
    }
    return self;
}

-(void) setLineWidth:(CGFloat)lineWidth{
    _lineWidth = lineWidth / [[UIScreen mainScreen] scale];
}

@end

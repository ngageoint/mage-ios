//
//  StyledPolyline.m
//  MAGE
//
//  Created by Dan Barela on 2/2/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "StyledPolyline.h"
#import <HexColor.h>

@implementation StyledPolyline

- (void) lineColorWithHexString: (NSString *) hex andAlpha: (CGFloat) alpha {
    _lineColor = [UIColor colorWithHexString:hex alpha:alpha];
}

- (void) lineColorWithHexString: (NSString *) hex {
    _lineColor = [UIColor colorWithHexString:hex];
}

@end

//
//  StyledPolygon.m
//  MAGE
//
//  This class exists so that I can keep style information with the polygons
//  and style them correctly.
//
//  Created by Dan Barela on 2/2/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "StyledPolygon.h"
#import <HexColor.h>

@implementation StyledPolygon

- (void) fillColorWithHexString: (NSString *) hex andAlpha: (CGFloat) alpha {
    _fillColor = [UIColor colorWithHexString:hex alpha:alpha];
}

- (void) fillColorWithHexString: (NSString *) hex {
    _fillColor = [UIColor colorWithHexString:hex];
}

- (void) lineColorWithHexString: (NSString *) hex andAlpha: (CGFloat) alpha {
    _lineColor = [UIColor colorWithHexString:hex alpha:alpha];
}

- (void) lineColorWithHexString: (NSString *) hex {
    _lineColor = [UIColor colorWithHexString:hex];
}
- (void) setTitlet:(NSString *)title {
    NSLog(@"clown");
    self.title = title;
}

@end

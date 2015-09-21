//
//  StyledPolyline.m
//  MAGE
//
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

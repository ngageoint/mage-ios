//
//  StyledPolyline.m
//  MAGE
//
//

@import HexColors;

#import "StyledPolyline.h"

@implementation StyledPolyline

+(StyledPolyline *) createWithPolyline: (MKPolyline *) polyline{
    StyledPolyline * styledPolyline = [StyledPolyline polylineWithPoints:[polyline points] count:polyline.pointCount];
    [styledPolyline setTitle:polyline.title];
    [styledPolyline setSubtitle:polyline.subtitle];
    [styledPolyline setLineColor:UIColor.blackColor];
    [styledPolyline setLineWidth:1.0];
    return styledPolyline;
}

- (void) lineColorWithHexString: (NSString *) hex andAlpha: (CGFloat) alpha {
    _lineColor = [UIColor colorWithHexString:hex alpha:alpha];
}

- (void) lineColorWithHexString: (NSString *) hex {
    _lineColor = [UIColor colorWithHexString:hex];
}

@end

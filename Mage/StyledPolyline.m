//
//  StyledPolyline.m
//  MAGE
//
//

@import HexColors;

#import "StyledPolyline.h"

@implementation StyledPolyline

+ (StyledPolyline *) createWithPolyline: (MKPolyline *) polyline {
    StyledPolyline * styledPolyline = [StyledPolyline polylineWithPoints:[polyline points] count:polyline.pointCount];
    [styledPolyline setTitle:polyline.title];
    [styledPolyline setSubtitle:polyline.subtitle];
    [styledPolyline applyDefaultStyle];
    
    return styledPolyline;
}

+ (StyledPolyline *) polylineWithPoints:(const MKMapPoint *)points count:(NSUInteger)count {
    StyledPolyline *styledPolyline = [super polylineWithPoints:points count:count];
    [styledPolyline applyDefaultStyle];

    return styledPolyline;
}

+ (StyledPolyline *) polylineWithCoordinates:(const CLLocationCoordinate2D *)coords count:(NSUInteger)count {
    StyledPolyline *styledPolyline = [super polylineWithCoordinates:coords count:count];
    [styledPolyline applyDefaultStyle];
    
    return styledPolyline;
}

- (void) applyDefaultStyle {
    [self setLineColor:UIColor.blackColor];
    [self setLineWidth:1.0];
}

- (void) lineColorWithHexString: (NSString *) hex andAlpha: (CGFloat) alpha {
    if (hex) {
        _lineColor = [UIColor colorWithHexString:hex alpha:alpha];
    }
}

- (void) lineColorWithHexString: (NSString *) hex {
    if (hex) {
        _lineColor = [UIColor colorWithHexString:hex];
    }
}

@end

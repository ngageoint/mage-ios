//
//  StyledPolygon.m
//  MAGE
//
//  This class exists so that I can keep style information with the polygons
//  and style them correctly.
//
//

#import "StyledPolygon.h"
#import <HexColor.h>

@implementation StyledPolygon

+(StyledPolygon *) createWithPolygon: (MKPolygon *) polygon{
    StyledPolygon * styledPolygon = [StyledPolygon polygonWithPoints:[polygon points] count:polygon.pointCount interiorPolygons:[polygon interiorPolygons]];
    [styledPolygon setTitle:polygon.title];
    [styledPolygon setSubtitle:polygon.subtitle];
    [styledPolygon setLineColor:UIColor.blackColor];
    [styledPolygon setLineWidth:1.0];
    [styledPolygon setFillColor:nil];
    return styledPolygon;
}

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

@end

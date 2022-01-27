//
//  StyledPolygon.m
//  MAGE
//
//  This class exists so that I can keep style information with the polygons
//  and style them correctly.
//
//

@import HexColors;

#import "StyledPolygon.h"

@implementation StyledPolygon

+ (StyledPolygon *) generatePolygon:(NSArray *) coordinates {
    //exterior polygon
    NSMutableArray *exteriorPolygonCoordinates = coordinates[0];
    NSMutableArray *interiorPolygonCoordinates = [[NSMutableArray alloc] init];
    
    
    CLLocationCoordinate2D exteriorMapCoordinates[exteriorPolygonCoordinates.count];
    for (NSInteger index = 0; index < exteriorPolygonCoordinates.count; index++) {
        NSNumber *y = exteriorPolygonCoordinates[index][0];
        NSNumber *x = exteriorPolygonCoordinates[index][1];
        
        exteriorMapCoordinates[index] = CLLocationCoordinate2DMake([x doubleValue], [y doubleValue]);
    }
    
    //interior polygons
    NSMutableArray *interiorPolygons = [[NSMutableArray alloc] init];
    if (coordinates.count > 1) {
        [interiorPolygonCoordinates addObjectsFromArray:coordinates];
        [interiorPolygonCoordinates removeObjectAtIndex:0];
        MKPolygon *recursePolygon = [StyledPolygon generatePolygon:interiorPolygonCoordinates];
        [interiorPolygons addObject:recursePolygon];
    }
    
    StyledPolygon *exteriorPolygon;
    if (interiorPolygons.count > 0) {
        exteriorPolygon = [StyledPolygon polygonWithCoordinates:exteriorMapCoordinates count:exteriorPolygonCoordinates.count interiorPolygons:[NSArray arrayWithArray:interiorPolygons]];
    }
    else {
        exteriorPolygon = [StyledPolygon polygonWithCoordinates:exteriorMapCoordinates count:exteriorPolygonCoordinates.count];
    }
    
    return exteriorPolygon;
}


+ (StyledPolygon *) createWithPolygon: (MKPolygon *) polygon{
    StyledPolygon * styledPolygon = [StyledPolygon polygonWithPoints:[polygon points] count:polygon.pointCount interiorPolygons:[polygon interiorPolygons]];
    [styledPolygon setTitle:polygon.title];
    [styledPolygon setSubtitle:polygon.subtitle];
    [styledPolygon applyDefaultStyle];
    
    return styledPolygon;
}

+ (StyledPolygon *)polygonWithPoints:(const MKMapPoint *)points count:(NSUInteger)count {
    StyledPolygon * styledPolygon = [super polygonWithPoints:points count:count];
    [styledPolygon applyDefaultStyle];

    return styledPolygon;
}

+ (StyledPolygon *)polygonWithPoints:(const MKMapPoint *)points count:(NSUInteger)count interiorPolygons:(nullable NSArray<MKPolygon *> *)interiorPolygons {
    StyledPolygon * styledPolygon = [super polygonWithPoints:points count:count interiorPolygons:interiorPolygons];
    [styledPolygon applyDefaultStyle];

    return styledPolygon;
}

+ (StyledPolygon *)polygonWithCoordinates:(const CLLocationCoordinate2D *)coords count:(NSUInteger)count {
    StyledPolygon * styledPolygon = [super polygonWithCoordinates:coords count:count];
    [styledPolygon applyDefaultStyle];

    return styledPolygon;
}

+ (StyledPolygon *)polygonWithCoordinates:(const CLLocationCoordinate2D *)coords count:(NSUInteger)count interiorPolygons:(nullable NSArray<MKPolygon *> *)interiorPolygons {
    StyledPolygon * styledPolygon = [super polygonWithCoordinates:coords count:count interiorPolygons:interiorPolygons];
    [styledPolygon applyDefaultStyle];

    return styledPolygon;
}

- (void) applyDefaultStyle {
    [self setLineColor:UIColor.blackColor];
    [self setLineWidth:1.0];
    [self setFillColor:nil];
}

- (void) fillColorWithHexString: (NSString *) hex andAlpha: (CGFloat) alpha {
    if (hex) {
        _fillColor = [UIColor hx_colorWithHexRGBAString:hex alpha:alpha];
    }
}

- (void) fillColorWithHexString: (NSString *) hex {
    if (hex) {
        _fillColor = [UIColor hx_colorWithHexRGBAString:hex];
    }
}

- (void) lineColorWithHexString: (NSString *) hex andAlpha: (CGFloat) alpha {
    if (hex) {
        _lineColor = [UIColor hx_colorWithHexRGBAString:hex alpha:alpha];
    }
}

- (void) lineColorWithHexString: (NSString *) hex {
    if (hex) {
        _lineColor = [UIColor hx_colorWithHexRGBAString:hex];
    }
}

@end

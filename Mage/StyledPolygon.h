//
//  StyledPolygon.h
//  MAGE
//
//

#import <MapKit/MapKit.h>

@interface StyledPolygon : MKPolygon

@property (nonatomic) UIColor *fillColor;
@property (nonatomic) UIColor *lineColor;
@property (nonatomic) CGFloat lineWidth;

+ (StyledPolygon *) createWithPolygon: (MKPolygon *) polygon;

+ (StyledPolygon *)polygonWithPoints:(const MKMapPoint *)points count:(NSUInteger)count;
+ (StyledPolygon *)polygonWithPoints:(const MKMapPoint *)points count:(NSUInteger)count interiorPolygons:(nullable NSArray<MKPolygon *> *)interiorPolygons;

+ (StyledPolygon *)polygonWithCoordinates:(const CLLocationCoordinate2D *)coords count:(NSUInteger)count;
+ (StyledPolygon *)polygonWithCoordinates:(const CLLocationCoordinate2D *)coords count:(NSUInteger)count interiorPolygons:(nullable NSArray<MKPolygon *> *)interiorPolygons;

- (void) fillColorWithHexString: (NSString *) hex andAlpha: (CGFloat) alpha;
- (void) fillColorWithHexString: (NSString *) hex;
- (void) lineColorWithHexString: (NSString *) hex andAlpha: (CGFloat) alpha;
- (void) lineColorWithHexString: (NSString *) hex;

@end

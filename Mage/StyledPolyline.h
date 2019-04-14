//
//  StyledPolyline.h
//  MAGE
//
//

#import <MapKit/MapKit.h>

@interface StyledPolyline : MKPolyline

@property (nonatomic) UIColor *lineColor;
@property (nonatomic) CGFloat lineWidth;

+ (StyledPolyline *) createWithPolyline: (MKPolyline *) polyline;
+ (StyledPolyline *) polylineWithPoints:(const MKMapPoint *)points count:(NSUInteger)count;
+ (StyledPolyline *) polylineWithCoordinates:(const CLLocationCoordinate2D *)coords count:(NSUInteger)count;

- (void) lineColorWithHexString: (NSString *) hex andAlpha: (CGFloat) alpha;
- (void) lineColorWithHexString: (NSString *) hex;

@end

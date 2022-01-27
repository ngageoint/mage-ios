//
//  StyledPolyline.h
//  MAGE
//
//

#import <MapKit/MapKit.h>

@interface StyledPolyline : MKPolyline

@property (nonatomic) UIColor *lineColor;
@property (nonatomic) CGFloat lineWidth;
@property (nonatomic) NSString *observationRemoteId;
NS_ASSUME_NONNULL_BEGIN

+ (StyledPolyline *) generatePolyline:(NSArray *) path;
+ (StyledPolyline *) createWithPolyline: (MKPolyline *) polyline;
+ (StyledPolyline *) polylineWithPoints:(const MKMapPoint *)points count:(NSUInteger)count;
+ (StyledPolyline *) polylineWithCoordinates:(const CLLocationCoordinate2D *)coords count:(NSUInteger)count;

- (void) lineColorWithHexString: (NSString *) hex andAlpha: (CGFloat) alpha;
- (void) lineColorWithHexString: (NSString *) hex;
NS_ASSUME_NONNULL_END

@end

//
//  StyledPolygon.h
//  MAGE
//
//

#import <MapKit/MapKit.h>

@interface StyledPolygon : MKPolygon

@property (nonatomic) UIColor * _Nullable fillColor;
@property (nonatomic) UIColor * _Nullable lineColor;
@property (nonatomic) CGFloat lineWidth;
@property (nonatomic) NSString * _Nullable observationRemoteId;


NS_ASSUME_NONNULL_BEGIN

+ (StyledPolygon *) createWithPolygon: (MKPolygon *) polygon;
+ (StyledPolygon *) generatePolygon:(NSArray *) coordinates;

+ (StyledPolygon *)polygonWithPoints:(const MKMapPoint *)points count:(NSUInteger)count;
+ (StyledPolygon *)polygonWithPoints:(const MKMapPoint *)points count:(NSUInteger)count interiorPolygons:(nullable NSArray<MKPolygon *> *)interiorPolygons;

+ (StyledPolygon *)polygonWithCoordinates:(const CLLocationCoordinate2D *)coords count:(NSUInteger)count;
+ (StyledPolygon *)polygonWithCoordinates:(const CLLocationCoordinate2D *)coords count:(NSUInteger)count interiorPolygons:(nullable NSArray<MKPolygon *> *)interiorPolygons;

- (void) fillColorWithHexString: (NSString *) hex andAlpha: (CGFloat) alpha;
- (void) fillColorWithHexString: (NSString *) hex;
- (void) lineColorWithHexString: (NSString *) hex andAlpha: (CGFloat) alpha;
- (void) lineColorWithHexString: (NSString *) hex;
NS_ASSUME_NONNULL_END

@end


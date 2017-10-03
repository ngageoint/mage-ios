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
+(StyledPolygon *) createWithPolygon: (MKPolygon *) polygon;
- (void) fillColorWithHexString: (NSString *) hex andAlpha: (CGFloat) alpha;
- (void) fillColorWithHexString: (NSString *) hex;
- (void) lineColorWithHexString: (NSString *) hex andAlpha: (CGFloat) alpha;
- (void) lineColorWithHexString: (NSString *) hex;

@end

//
//  StyledPolyline.h
//  MAGE
//
//

#import <MapKit/MapKit.h>

@interface StyledPolyline : MKPolyline

@property (nonatomic) UIColor *lineColor;
@property (nonatomic) CGFloat lineWidth;
+(StyledPolyline *) createWithPolyline: (MKPolyline *) polyline;
- (void) lineColorWithHexString: (NSString *) hex andAlpha: (CGFloat) alpha;
- (void) lineColorWithHexString: (NSString *) hex;

@end

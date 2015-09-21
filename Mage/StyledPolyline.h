//
//  StyledPolyline.h
//  MAGE
//
//

#import <MapKit/MapKit.h>

@interface StyledPolyline : MKPolyline

@property (nonatomic, readonly) UIColor *lineColor;
@property (nonatomic) CGFloat lineWidth;
- (void) lineColorWithHexString: (NSString *) hex andAlpha: (CGFloat) alpha;
- (void) lineColorWithHexString: (NSString *) hex;

@end

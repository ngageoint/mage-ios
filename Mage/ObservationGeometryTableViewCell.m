//
//  ObservationGeometryTableViewCell.m
//  Mage
//
//

#import "ObservationGeometryTableViewCell.h"
#import "WKBGeometry.h"
#import "WKBGeometryUtils.h"

@implementation ObservationGeometryTableViewCell

- (void) populateCellWithKey:(id) key andValue:(id) value {
    if ([value isKindOfClass:[WKBGeometry class]]) {
        WKBGeometry *geometry = value;
        WKBPoint *centroid = [WKBGeometryUtils centroidOfGeometry:geometry];
        NSString *geoString = [NSString stringWithFormat:@"%.6f, %.6f", [centroid.y doubleValue], [centroid.x doubleValue]];
        self.valueTextView.text = [NSString stringWithFormat:@"%@", geoString];
    } else {
        NSDictionary *geometry = value;
        NSString *geoString = [NSString stringWithFormat:@"%.6f, %.6f", [[geometry objectForKey:@"y"] floatValue], [[geometry objectForKey:@"x"] floatValue]];
        self.valueTextView.text = [NSString stringWithFormat:@"%@", geoString];
    }
    self.keyLabel.text = [NSString stringWithFormat:@"%@", key];
}

@end

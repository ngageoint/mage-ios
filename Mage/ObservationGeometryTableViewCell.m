//
//  ObservationGeometryTableViewCell.m
//  Mage
//
//  Created by Dan Barela on 7/23/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationGeometryTableViewCell.h"
#import <GeoPoint.h>

@implementation ObservationGeometryTableViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void) populateCellWithKey:(id) key andValue:(id) value {
    if ([value isKindOfClass:[GeoPoint class]]) {
        GeoPoint *geoPoint = value;
        NSString *geoString = [NSString stringWithFormat:@"%.6f, %.6f", geoPoint.location.coordinate.latitude, geoPoint.location.coordinate.longitude];
        self.valueTextView.text = [NSString stringWithFormat:@"%@", geoString];
    } else {
        NSDictionary *geometry = value;
        NSString *geoString = [NSString stringWithFormat:@"%.6f, %.6f", [[geometry objectForKey:@"y"] floatValue], [[geometry objectForKey:@"x"] floatValue]];
        self.valueTextView.text = [NSString stringWithFormat:@"%@", geoString];
    }
    self.keyLabel.text = [NSString stringWithFormat:@"%@", key];
}

@end

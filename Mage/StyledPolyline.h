//
//  StyledPolyline.h
//  MAGE
//
//  Created by Dan Barela on 2/2/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <MapKit/MapKit.h>

@interface StyledPolyline : MKPolyline

@property (nonatomic, readonly) UIColor *lineColor;
@property (nonatomic) CGFloat lineWidth;
- (void) lineColorWithHexString: (NSString *) hex andAlpha: (CGFloat) alpha;
- (void) lineColorWithHexString: (NSString *) hex;

@end

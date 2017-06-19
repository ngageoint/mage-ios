//
//  ObservationShapeStyle.h
//  MAGE
//
//  Created by Brian Osborn on 6/19/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 * Observation shape style for lines and polygons including stroke width, stroke color, and fill color
 */
@interface ObservationShapeStyle : NSObject

/**
 * Line width for lines and polygons
 */
@property (nonatomic) CGFloat lineWidth;

/**
 * Stroke color for lines and polygons
 */
@property (nonatomic) UIColor *strokeColor;

/**
 * Fill color for polygons
 */
@property (nonatomic) UIColor *fillColor;

/**
 * Initializer
 */
- (id)init;

@end

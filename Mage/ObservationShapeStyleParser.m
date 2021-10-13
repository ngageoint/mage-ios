//
//  ObservationShapeStyleParser.m
//  MAGE
//
//  Created by Brian Osborn on 6/19/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//
@import HexColors;
#import "ObservationShapeStyleParser.h"
#import "Server.h"

@implementation ObservationShapeStyleParser

static NSString * const STYLE_ELEMENT = @"style";
static NSString * const FILL_ELEMENT = @"fill";
static NSString * const STROKE_ELEMENT = @"stroke";
static NSString * const FILL_OPACITY_ELEMENT = @"fillOpacity";
static NSString * const STROKE_OPACITY_ELEMENT = @"strokeOpacity";
static NSString * const STROKE_WIDTH_ELEMENT = @"strokeWidth";

+(ObservationShapeStyle *) styleOfObservation: (Observation *) observation{
    
    ObservationShapeStyle *style = [[ObservationShapeStyle alloc] init];
    
    NSDictionary *form = [observation getPrimaryEventForm];
    
    // Check for a style
    NSDictionary *styleField = [form objectForKey: STYLE_ELEMENT];
    if(styleField != nil && styleField.count > 0){
        
        // Found the top level style
        NSString *type = [observation primaryFieldText];
        
        // Check for a type within the style
        NSDictionary *typeField = [styleField objectForKey:type];
        if(typeField != nil && typeField.count > 0){
            
            // Found the type level style
            styleField = typeField;
            
            // Check for a variant
            
            NSString *variant = [observation secondaryFieldText];
            if (variant != nil) {
                // Check for a variant within the style type
                NSDictionary *typeVariantField = [styleField objectForKey:variant];
                if(typeVariantField != nil && typeVariantField.count > 0){
                    
                    // Found the variant level style
                    styleField = typeVariantField;
                }
            }
        }
        
        // Get the style properties
        NSString *fill = [styleField objectForKey:FILL_ELEMENT];
        NSString *stroke = [styleField objectForKey:STROKE_ELEMENT];
        float fillOpacity = [((NSNumber *)[styleField objectForKey:FILL_OPACITY_ELEMENT]) floatValue];
        float strokeOpacity = [((NSNumber *)[styleField objectForKey:STROKE_OPACITY_ELEMENT]) floatValue];
        float strokeWidth = [((NSNumber *)[styleField objectForKey:STROKE_WIDTH_ELEMENT]) floatValue];
        
        // Set the stroke width
        [style setLineWidth:strokeWidth];
        
        // Create and set the stroke color
        UIColor *strokeColor = [UIColor colorWithHexString:stroke alpha:strokeOpacity];
        [style setStrokeColor:strokeColor];
        
        // Create and set the fill color
        UIColor *fillColor = [UIColor colorWithHexString:fill alpha:fillOpacity];
        [style setFillColor:fillColor];
    }
    
    return style;
}

@end

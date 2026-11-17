//
//  ObservationShapeStyleParser.m
//  MAGE
//
//  Created by Brian Osborn on 6/19/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//
@import HexColors;
@import Persistence;
#import "ObservationShapeStyleParser.h"
#import "MAGE-Swift.h"

@implementation ObservationShapeStyleParser

static NSString * const STYLE_ELEMENT = @"style";
static NSString * const FILL_ELEMENT = @"fill";
static NSString * const STROKE_ELEMENT = @"stroke";
static NSString * const FILL_OPACITY_ELEMENT = @"fillOpacity";
static NSString * const STROKE_OPACITY_ELEMENT = @"strokeOpacity";
static NSString * const STROKE_WIDTH_ELEMENT = @"strokeWidth";

+(ObservationShapeStyle *) styleOfObservation: (NSManagedObject *) observation{
    Observation *strongObservation = (Observation *)observation;
    ObservationShapeStyle *style = [[ObservationShapeStyle alloc] init];
    
    Form *form = strongObservation.primaryEventForm;
    
    // Check for a style
    NSDictionary *styleField = form.style;
    if(styleField != nil && styleField.count > 0){
        
        // Found the top level style
        NSString *type = [strongObservation primaryFieldText];
        
        // Check for a type within the style.
        // Server style JSON problem: type and variant names are keys in the same object as
        // the style properties, so an option named "fill", "stroke", etc. collides with a
        // property and finds a value like "#ff0000" instead of a style. Guard against it by
        // only using entries that are dictionaries, otherwise fall back to the parent style.
        NSDictionary *typeField = [ObservationShapeStyleParser styleIn:styleField forKey:type];
        if(typeField != nil && typeField.count > 0){
            
            // Found the type level style
            styleField = typeField;
            
            // Check for a variant
            
            NSString *variant = [strongObservation secondaryFieldText];
            if (variant != nil) {
                // Check for a variant within the style type
                NSDictionary *typeVariantField = [ObservationShapeStyleParser styleIn:styleField forKey:variant];
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
        UIColor *strokeColor = [UIColor hx_colorWithHexRGBAString:stroke alpha:strokeOpacity];
        [style setStrokeColor:strokeColor];
        
        // Create and set the fill color
        UIColor *fillColor = [UIColor hx_colorWithHexRGBAString:fill alpha:fillOpacity];
        [style setFillColor:fillColor];
    }
    
    return style;
}

+(NSDictionary *) styleIn: (NSDictionary *) style forKey: (NSString *) key{
    if (key == nil) {
        return nil;
    }
    id value = [style objectForKey:key];
    return [value isKindOfClass:[NSDictionary class]] ? value : nil;
}

@end

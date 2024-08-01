//
//  ObservationShapeStyleParser.m
//  MAGE
//
//  Created by Brian Osborn on 6/19/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

@objc class ObservationShapeStyleParser: NSObject {
    @Injected(\.formRepository)
    static var formRepository: FormRepository
    
    static let STYLE_ELEMENT = "style"
    static let FILL_ELEMENT = "fill"
    static let STROKE_ELEMENT = "stroke"
    static let FILL_OPACITY_ELEMENT = "fillOpacity";
    static let STROKE_OPACITY_ELEMENT = "strokeOpacity";
    static let STROKE_WIDTH_ELEMENT = "strokeWidth";
    
    @objc static func style(
        observation: Observation
    ) -> ObservationShapeStyle {
        let primaryFieldText = observation.primaryFieldText
        let secondaryFieldText = observation.secondaryFieldText
        return ObservationShapeStyleParser.style(
            observation: observation,
            primaryFieldText: primaryFieldText,
            secondaryFieldText: secondaryFieldText
        )
    }
    
    @objc static func style(
        observation: Observation,
        primaryFieldText: String? = nil,
        secondaryFieldText: String? = nil
    ) -> ObservationShapeStyle {
        let style = ObservationShapeStyle()
        
        var form: Form?
        if let primaryObservationForm = observation.primaryObservationForm, 
            let formId = primaryObservationForm[EventKey.formId.key] as? NSNumber
        {
            form = ObservationShapeStyleParser.formRepository.getForm(formId: formId)
        }
        
//        let form = observation.primaryEventForm
        
        // Check for a style
        var styleField = form?.style
        if styleField != nil, (styleField?.count ?? 0) > 0 {
            
            // Found the top level style
            let type = primaryFieldText
            
            // Check for a type within the style
            if let typeField = styleField?[type] as? [AnyHashable: Any], !typeField.isEmpty {
                // Found the type level style
                styleField = typeField
                
                // Check for a variant
                
                if let variant = secondaryFieldText {
                    // Check for a variant within the style type
                    if let typeVariantField = styleField?[variant] as? [AnyHashable: Any], typeVariantField.count > 0 {
                        // Found the variant level style
                        styleField = typeVariantField
                    }
                }
            }
            
            // Get the style properties
            let fill = styleField?[ObservationShapeStyleParser.FILL_ELEMENT] as? String
            let stroke = styleField?[ObservationShapeStyleParser.STROKE_ELEMENT] as? String
            let fillOpacity = styleField?[ObservationShapeStyleParser.FILL_OPACITY_ELEMENT] as? CGFloat
            let strokeOpacity = styleField?[ObservationShapeStyleParser.STROKE_OPACITY_ELEMENT] as? CGFloat
            let strokeWidth = styleField?[ObservationShapeStyleParser.STROKE_WIDTH_ELEMENT] as? CGFloat
            
            // Set the stroke width
            if let strokeWidth = strokeWidth {
                style.setLineWidth(lineWidth: CGFloat(strokeWidth))
            }
            
            // Create and set the stroke color
            if let stroke = stroke, let strokeColor = UIColor(hex: stroke)?.withAlphaComponent(CGFloat(strokeOpacity ?? 1.0)) {
                style.strokeColor = strokeColor
            }
            
            // Create and set the fill color
            if let fill = fill, let fillColor = UIColor(hex: fill)?.withAlphaComponent(CGFloat(fillOpacity ?? 1.0)) {
                style.fillColor = fillColor
            }
        }
        
        return style
    }
}

//@import HexColors;
//#import "ObservationShapeStyleParser.h"
//#import "MAGE-Swift.h"
//
//@implementation ObservationShapeStyleParser
//
//static NSString * const STYLE_ELEMENT = @"style";
//static NSString * const FILL_ELEMENT = @"fill";
//static NSString * const STROKE_ELEMENT = @"stroke";
//static NSString * const FILL_OPACITY_ELEMENT = @"fillOpacity";
//static NSString * const STROKE_OPACITY_ELEMENT = @"strokeOpacity";
//static NSString * const STROKE_WIDTH_ELEMENT = @"strokeWidth";
//
//+(ObservationShapeStyle *) styleOfObservation: (Observation *) observation{
//    
//    ObservationShapeStyle *style = [[ObservationShapeStyle alloc] init];
//    
//    Form *form = observation.primaryEventForm;
//    
//    // Check for a style
//    NSDictionary *styleField = form.style;
//    if(styleField != nil && styleField.count > 0){
//        
//        // Found the top level style
//        NSString *type = [observation primaryFieldText];
//        
//        // Check for a type within the style
//        NSDictionary *typeField = [styleField objectForKey:type];
//        if(typeField != nil && typeField.count > 0){
//            
//            // Found the type level style
//            styleField = typeField;
//            
//            // Check for a variant
//            
//            NSString *variant = [observation secondaryFieldText];
//            if (variant != nil) {
//                // Check for a variant within the style type
//                NSDictionary *typeVariantField = [styleField objectForKey:variant];
//                if(typeVariantField != nil && typeVariantField.count > 0){
//                    
//                    // Found the variant level style
//                    styleField = typeVariantField;
//                }
//            }
//        }
//        
//        // Get the style properties
//        NSString *fill = [styleField objectForKey:FILL_ELEMENT];
//        NSString *stroke = [styleField objectForKey:STROKE_ELEMENT];
//        float fillOpacity = [((NSNumber *)[styleField objectForKey:FILL_OPACITY_ELEMENT]) floatValue];
//        float strokeOpacity = [((NSNumber *)[styleField objectForKey:STROKE_OPACITY_ELEMENT]) floatValue];
//        float strokeWidth = [((NSNumber *)[styleField objectForKey:STROKE_WIDTH_ELEMENT]) floatValue];
//        
//        // Set the stroke width
//        [style setLineWidth:strokeWidth];
//        
//        // Create and set the stroke color
//        UIColor *strokeColor = [UIColor hx_colorWithHexRGBAString:stroke alpha:strokeOpacity];
//        [style setStrokeColor:strokeColor];
//        
//        // Create and set the fill color
//        UIColor *fillColor = [UIColor hx_colorWithHexRGBAString:fill alpha:fillOpacity];
//        [style setFillColor:fillColor];
//    }
//    
//    return style;
//}
//
//@end

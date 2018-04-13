//
//  FormCollectionViewCell.m
//  MAGE
//
//  Created by Dan Barela on 8/10/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//
@import HexColors;
#import "FormCollectionViewCell.h"
#import "Theme+UIResponder.h"

@implementation FormCollectionViewCell

- (void) themeDidChange:(MageTheme)theme {
    self.formNameLabel.textColor = [UIColor brand];

    self.circleView.backgroundColor = [UIColor colorWithHexString:[self.form objectForKey:@"color"] alpha:1.0f];
    self.circleView.layer.borderColor = [[UIColor themedWhite] CGColor];
    self.circleView.layer.cornerRadius = self.circleView.frame.size.width / 2;
    self.circleView.layer.borderWidth = 5;
    [self createOutlineWithColor:[UIColor lightGrayColor] aroundMarkerWithColor:[UIColor brightButton]];
}

- (CALayer *) createInnerLineWithColor: (UIColor *) color {
    CALayer *borderLayer = [[CALayer alloc] init];
    borderLayer.frame = CGRectMake(0, 0, self.circleView.frame.size.width, self.circleView.frame.size.width);
    borderLayer.backgroundColor = [UIColor clearColor].CGColor;
    borderLayer.cornerRadius = borderLayer.frame.size.width / 2;
    borderLayer.borderColor = color.CGColor;
    borderLayer.borderWidth = 6;
    
    return borderLayer;
}

- (CALayer *) createOtherInnerLineWithColor: (UIColor *) color {
    CALayer *borderLayer = [[CALayer alloc] init];
    borderLayer.frame = CGRectMake(5, 5, self.circleView.frame.size.width-10, self.circleView.frame.size.width-10);
    borderLayer.backgroundColor = [UIColor clearColor].CGColor;
    borderLayer.cornerRadius = borderLayer.frame.size.width / 2;
    borderLayer.borderColor = [color colorWithAlphaComponent:.8].CGColor;
    borderLayer.borderWidth = 1.5;
    
    return borderLayer;
}

- (void) createOutlineWithColor: (UIColor *) outlineColor aroundMarkerWithColor: (UIColor *) color {
    UIImage *marker = [UIImage imageNamed:@"marker"];
    UIGraphicsBeginImageContextWithOptions(marker.size, NO, marker.scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [color setFill];
    CGContextTranslateCTM(context, 0, marker.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextClipToMask(context, CGRectMake(0, 0, marker.size.width, marker.size.height), [marker CGImage]);
    CGContextFillRect(context, CGRectMake(0, 0, marker.size.width, marker.size.height));
    
    marker = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();

    CGFloat outlineCoefficient = 1.08;
    
    CGRect outlineImageRect = CGRectMake(0, 0, marker.size.width * outlineCoefficient, marker.size.height * outlineCoefficient);
    
    CGRect imageRect = CGRectMake(marker.size.width * (outlineCoefficient - 1) * .5, marker.size.height * (outlineCoefficient - 1) * .5, marker.size.width, marker.size.height);
    
    UIGraphicsBeginImageContextWithOptions(outlineImageRect.size, NO, outlineCoefficient);
    [marker drawInRect:outlineImageRect];
    
    context = UIGraphicsGetCurrentContext();
    CGContextSetBlendMode(context, kCGBlendModeSourceIn);
    CGContextSetFillColorWithColor(context, outlineColor.CGColor);
    CGContextFillRect(context, outlineImageRect);
    [marker drawInRect:imageRect];
    
    UIImage *newMarker = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.markerView.image = newMarker;
}

- (void) configureCellForForm: (NSDictionary *) form {
    self.form = form;
    self.formNameLabel.text = [form objectForKey:@"name"];
    
    [self registerForThemeChanges];
}

@end

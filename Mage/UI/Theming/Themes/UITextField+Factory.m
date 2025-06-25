//
//  UITextField+Factory.m
//  MAGE
//
//  Created by Brent Michalski on 6/25/25.
//  Copyright © 2025 National Geospatial Intelligence Agency. All rights reserved.
//

#import "UITextField+Factory.h"
#import "AppContainerScheming.h"

@implementation UITextField (Factory)

+ (UITextField *)themedTextFieldWithPlaceholder:(NSString *)placeholder
                                          scheme:(id<AppContainerScheming>)scheme
                                         target:(id)target
                                         action:(SEL)selector {
    UITextField *textField = [[UITextField alloc] init];
    textField.translatesAutoresizingMaskIntoConstraints = NO;
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.accessibilityLabel = placeholder;
    textField.placeholder = placeholder;
    textField.returnKeyType = UIReturnKeyDone;
    [textField addTarget:target action:selector forControlEvents:UIControlEventEditingChanged];
    
    [textField applyPrimaryThemeWithScheme:scheme];
    
    return textField;
}

@end


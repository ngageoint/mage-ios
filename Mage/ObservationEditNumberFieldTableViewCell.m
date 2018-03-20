//
//  ObservationEditNumberFieldTableViewCell.m
//  MAGE
//
//  Created by William Newman on 4/10/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationEditNumberFieldTableViewCell.h"
#import "Theme+UIResponder.h"

@import HexColors;

@interface ObservationEditNumberFieldTableViewCell ()
@property (strong, nonatomic) NSNumber *value;
@property (strong, nonatomic) UILabel *title;
@property (strong, nonatomic) UIBarButtonItem *doneButton;
@property (strong, nonatomic) NSNumber *min;
@property (strong, nonatomic) NSNumber *max;
@property (strong, nonatomic) NSNumberFormatter *decimalFormatter;

@end


@implementation ObservationEditNumberFieldTableViewCell

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor dialog];
    
    self.textField.textColor = [UIColor primaryText];
    self.textField.selectedLineColor = [UIColor brand];
    self.textField.selectedTitleColor = [UIColor brand];
    self.textField.placeholderColor = [UIColor secondaryText];
    self.textField.lineColor = [UIColor secondaryText];
    self.textField.titleColor = [UIColor secondaryText];
    self.textField.errorColor = [UIColor colorWithHexString:@"F44336" alpha:.87];
    self.textField.iconFont = [UIFont fontWithName:@"FontAwesome" size:15];
    self.textField.iconText = @"\U0000f292";
    self.textField.iconColor = [UIColor secondaryText];
}

- (void) didMoveToSuperview {
    [self registerForThemeChanges];
}

- (void) awakeFromNib {
    [super awakeFromNib];
    
    self.decimalFormatter = [[NSNumberFormatter alloc] init];
    self.decimalFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    [self.textField setDelegate: self];
}

- (void) setFieldDefinition:(NSDictionary *)fieldDefinition {
    [super setFieldDefinition:fieldDefinition];
    
    self.min = [self.fieldDefinition objectForKey:@"min"];
    self.max = [self.fieldDefinition objectForKey:@"max"];
    
    self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
    
    if (self.min || self.max) {
        self.title = [[UILabel alloc] init];
        
        NSString *title = nil;
        if (self.min && self.max) {
            title = [NSString stringWithFormat:@"Between %@ and %@", self.min, self.max];
        } else if (self.min) {
            title = [NSString stringWithFormat:@"Greater than %@", self.min];
        } else if (self.max) {
            title = [NSString stringWithFormat:@"Less than %@", self.max];
        }
        
        self.title.text = title;
        [self.title setFont:[UIFont systemFontOfSize:13]];
        [self.title sizeToFit];
    }

    UIBarButtonItem *cancelBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    toolbar.items = [NSArray arrayWithObjects:cancelBarButton, flexSpace, [[UIBarButtonItem alloc] initWithCustomView:self.title], flexSpace, self.doneButton, nil];
    self.textField.inputAccessoryView = toolbar;
}


- (void) populateCellWithFormField: (id) field andValue: (id) value {
    
    if (value != nil) {
        [self.textField setText:[value stringValue]];
    } else {
        [self.textField setText:@""];
    }

    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    self.value = [formatter numberFromString:self.textField.text];
    self.textField.placeholder = ![[field objectForKey: @"required"] boolValue] ? [field objectForKey:@"title"] : [NSString stringWithFormat:@"%@ %@", [field objectForKey:@"title"], @"*"];
}

- (void) selectRow {
    [self.textField becomeFirstResponder];
}

- (void) cancelButtonPressed {
    self.textField.text = [self.value stringValue];
    [self.textField resignFirstResponder];
}

- (void) doneButtonPressed {
    [self.textField resignFirstResponder];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    // validate maybe, unless shouldChangeCharactersInRange already validated
    NSString *text = textField.text;
    NSNumber *number = [self.decimalFormatter numberFromString:text];
    [self setValid:[self isValid:number]];
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    if (![[self.value stringValue] isEqualToString:self.textField.text]) {
        self.value = [formatter numberFromString:self.textField.text];
        if (self.delegate && [self.delegate respondsToSelector:@selector(observationField:valueChangedTo:reloadCell:)]) {
            [self.delegate observationField:self.fieldDefinition valueChangedTo:self.value reloadCell:NO];
        }
    }
}

- (BOOL) isValid {
    return [super isValid] && [self isValid: self.value];
}

- (BOOL) isValid: (NSNumber *) number {
    
    if (number == nil && [[self.fieldDefinition objectForKey: @"required"] boolValue]) {
        return NO;
    }
    
    if (number != nil) {
        if ((self.min && self.max && ([number doubleValue] < [self.min doubleValue] || [number doubleValue] > [self.max doubleValue])) ||
            (self.min && ([number doubleValue] < [self.min doubleValue])) ||
            (self.max && ([number doubleValue] > [self.max doubleValue])))  {
            return NO;
        }
    }

    return YES;
}

- (BOOL) isEmpty {
    return [self.textField.text length] == 0;
}

- (void) setValid:(BOOL) valid {
    [super setValid:valid];
    
    if (valid) {
        self.textField.errorMessage = nil;
    } else {
        self.textField.errorMessage = self.textField.placeholder;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSNumber *number = [self.decimalFormatter numberFromString:text];
    
    [self setValid:[self isValid:number]];
    
    // allow backspace
    if (!string.length) {
        return YES;
    }
    
    // check for number
    if ([self.decimalFormatter numberFromString:text]) {
        return YES;
    }
    
    return NO;
}

@end

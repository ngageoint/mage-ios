//
//  ObservationEditTableViewCell.m
//  Mage
//
//

#import "ObservationEditTableViewCell.h"

@implementation ObservationEditTableViewCell

- (void) populateCellWithFormField: (id) field andValue: (id) value {
}

- (void) selectRow {
}

- (void) setValid:(BOOL) valid {
    if (valid) {
        self.requiredIndicator.textColor = [UIColor darkGrayColor];
    } else {
        self.requiredIndicator.textColor = [UIColor redColor];
    }
}

- (BOOL) isValid {
    if ([[self.fieldDefinition objectForKey:@"required"] boolValue] && [self isEmpty]) {
        return NO;
    }
    
    return YES;
}

- (BOOL) isEmpty {
    return NO;
}

@end

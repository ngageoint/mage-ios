//
//  ObservationEditTableViewCell.m
//  Mage
//
//

#import "ObservationEditTableViewCell.h"

@implementation ObservationEditTableViewCell

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
}

- (void) selectRow {
}

- (void) setValid:(BOOL) valid {
    if (valid) {
        self.requiredIndicator.layer.borderColor = [[UIColor blackColor] CGColor];
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

//
//  ObservationEditTableViewCell.m
//  Mage
//
//

#import "ObservationEditTableViewCell.h"
#import "Theme+UIResponder.h"

@interface ObservationEditTableViewCell()

@end

@implementation ObservationEditTableViewCell

- (void) populateCellWithFormField: (id) field andValue: (id) value {
}

- (void) selectRow {
}

- (void) setValid:(BOOL) valid {
    self.fieldValueValid = valid;
}

- (BOOL) isValid {
    return [self isValid:YES];
}

- (BOOL) isValid:(BOOL) enforceRequired {
    if ([[self.fieldDefinition objectForKey:@"required"] boolValue] && enforceRequired && [self isEmpty]) {
        return NO;
    }
    
    return YES;
}

- (BOOL) isEmpty {
    return NO;
}

@end

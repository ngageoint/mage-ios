//
//  ObservationEditTableViewCell.m
//  Mage
//
//

#import "ObservationEditTableViewCell.h"

@implementation ObservationEditTableViewCell

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    [self.keyLabel setText:[field objectForKey:@"title"]];
    self.valueTextField.text = [observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]];
    [self.requiredIndicator setHidden: ![[field objectForKey: @"required"] boolValue]];
}

- (CGFloat) getCellHeightForValue: (id) value {
    return self.bounds.size.height;
}

- (void) selectRow {
}

- (void) setValid:(BOOL) valid {
    if (valid) {
        self.requiredIndicator.layer.borderColor = [[UIColor blackColor] CGColor];
    } else {
        self.requiredIndicator.textColor = [UIColor redColor];
    }
};

@end

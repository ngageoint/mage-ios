//
//  ObservationCheckboxTableViewCell.m
//  MAGE
//
//

#import "ObservationCheckboxTableViewCell.h"

@implementation ObservationCheckboxTableViewCell

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    id value = [observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]];
    
    if (value != nil) {
        [self.checkboxSwitch setOn:[value boolValue]];
    } else {
        [self.checkboxSwitch setOn:[[field objectForKey:@"value"] boolValue] ];
    }
    
    [self.keyLabel setText:[field objectForKey:@"title"]];
    [self.requiredIndicator setHidden: ![[field objectForKey: @"required"] boolValue]];
}

- (CGFloat) getCellHeightForValue: (id) value {
    return self.bounds.size.height;
}

@end

//
//  ObservationEditTextFieldTableViewCell.m
//  MAGE
//
//

#import "ObservationEditTextFieldTableViewCell.h"

@implementation ObservationEditTextFieldTableViewCell

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    id value = [observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]];
    
    if (value != nil) {
        [self.textField setText:value];
    } else {
        [self.textField setText:[field objectForKey:@"value"]];
    }
    
    [self.keyLabel setText:[field objectForKey:@"title"]];
    [self.requiredIndicator setHidden: ![[field objectForKey: @"required"] boolValue]];
}

@end

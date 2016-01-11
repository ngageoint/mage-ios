//
//  ObservationEditTextFieldTableViewCell.m
//  MAGE
//
//

#import "ObservationEditTextFieldTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

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

- (void) setValid:(BOOL) valid {
    [super setValid:valid];
        
    if (valid) {
        self.textField.layer.borderColor = nil;
    } else {
        self.textField.layer.cornerRadius = 4.0f;
        self.textField.layer.masksToBounds = YES;
        self.textField.layer.borderColor = [[UIColor redColor] CGColor];
        self.textField.layer.borderWidth = 1.0f;
    }
};


@end

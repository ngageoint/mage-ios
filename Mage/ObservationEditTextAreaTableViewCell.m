//
//  ObservationEditTextAreaTableViewCell.m
//  MAGE
//
//

#import "ObservationEditTextAreaTableViewCell.h"

@interface ObservationEditTextAreaTableViewCell ()
@property (strong, nonatomic) NSString *value;
@end

@implementation ObservationEditTextAreaTableViewCell

- (void) awakeFromNib {
    [super awakeFromNib];
    
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed)];
    UIBarButtonItem *cancelBarButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed)];
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    toolbar.items = [NSArray arrayWithObjects:cancelBarButton, flexSpace, barButton, nil];
    self.textArea.inputAccessoryView = toolbar;
    [self.textArea setDelegate: self];
}

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    id value = [observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]];
    if (value != nil) {
        [self.textArea setText:value];
    }
    
    self.value = self.textArea.text;
    
    [self.keyLabel setText:[field objectForKey:@"title"]];
    [self.requiredIndicator setHidden: ![[field objectForKey: @"required"] boolValue]];
}

- (void) selectRow {
    [self.textArea becomeFirstResponder];
}

- (void) cancelButtonPressed {
    self.textArea.text = self.value;
    [self.textArea resignFirstResponder];
}

- (void) doneButtonPressed {
    [self.textArea resignFirstResponder];
    self.value = self.textArea.text;
    if (self.delegate && [self.delegate respondsToSelector:@selector(observationField:valueChangedTo:reloadCell:)]) {
        [self.delegate observationField:self.fieldDefinition valueChangedTo:self.value reloadCell:NO];
    }
}

- (void) setValid:(BOOL) valid {
    [super setValid:valid];
    
    if (valid) {
        self.textArea.layer.borderColor = [[UIColor colorWithRed:(215/255.0) green:(215/255.0) blue:(215/255.0) alpha:1] CGColor];
    } else {
        self.textArea.layer.borderColor = [[UIColor redColor] CGColor];
    }
}

- (BOOL) isEmpty {
    return [self.textArea.text length] == 0;
}

@end

//
//  ObservationEditTextAreaTableViewCell.m
//  MAGE
//
//  Created by Dan Barela on 10/2/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationEditTextAreaTableViewCell.h"

@implementation ObservationEditTextAreaTableViewCell

- (void) awakeFromNib {
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self.textArea action:@selector(resignFirstResponder)];
    UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 320, 44)];
    toolbar.items = [NSArray arrayWithObjects:flexSpace, barButton, nil];
    self.textArea.inputAccessoryView = toolbar;
    [self.textArea setDelegate: self];
}

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    id value = [observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]];
    if (value != nil) {
        [self.textArea setText:value];
    } else {
        [self.textArea setText:[field objectForKey:@"value"]];
    }
    [self.keyLabel setText:[field objectForKey:@"title"]];
    [self.requiredIndicator setHidden: ![[field objectForKey: @"required"] boolValue]];
}

- (void) textViewDidEndEditing:(UITextView *)textView {
    [self.delegate observationField:self.fieldDefinition valueChangedTo:textView.text reloadCell:NO];
}

- (void) textViewDidBeginEditing:(UITextView *)textView {
    
}

@end

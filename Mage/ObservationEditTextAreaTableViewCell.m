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
    [self.textArea setDelegate: self];
}

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    id value = [observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]];
    [self.textArea setText:value];
    [self.keyLabel setText:[field objectForKey:@"title"]];
}

- (void) textViewDidEndEditing:(UITextView *)textView {
    [self.delegate observationField:self.fieldDefinition valueChangedTo:textView.text reloadCell:NO];
}

- (void) textViewDidBeginEditing:(UITextView *)textView {
    
}

@end

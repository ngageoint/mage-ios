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

- (CGFloat) getCellHeightForValue: (id) value {
    self.textArea.text = value;
    CGSize idealSize = [self.textArea sizeThatFits:CGSizeMake(self.textArea.textContainer.size.width, MAXFLOAT)];
    return idealSize.height + self.textArea.frame.origin.y + 15;
}

- (void) textViewDidChange:(UITextView *)textView {
    
    [self.delegate observationField:self.fieldDefinition valueChangedTo:textView.text];
}


@end

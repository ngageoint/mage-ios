//
//  ObservationPickerTableViewCell.m
//  Mage
//
//  Created by Dan Barela on 8/20/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationPickerTableViewCell.h"

@implementation ObservationPickerTableViewCell

UIPickerView *picker;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}


- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    [self.valueLabel setText:[observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]]];
    [self.keyLabel setText:[field objectForKey:@"title"]];
}


@end

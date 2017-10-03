//
//  ObservationSelectTableViewCell.m
//  MAGE
//
//  Created by William Newman on 6/3/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationMultiSelectTableViewCell.h"

@implementation ObservationMultiSelectTableViewCell

- (void) populateCellWithKey:(id)key andValue:(id)value {
    [super populateCellWithKey:key andValue:value];
    self.valueTextView.text = [value componentsJoinedByString:@", "];
}

@end

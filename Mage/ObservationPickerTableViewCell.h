//
//  ObservationPickerTableViewCell.h
//  Mage
//
//  Created by Dan Barela on 8/20/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationEditTableViewCell.h"

@interface ObservationPickerTableViewCell : ObservationEditTableViewCell

//@property (weak, nonatomic) IBOutlet UIPickerView *valuePicker;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;

@end

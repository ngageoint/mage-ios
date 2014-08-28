//
//  DatePickerTableViewCell.h
//  Mage
//
//  Created by Dan Barela on 8/22/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObservationEditTableViewCell.h"

@interface DatePickerTableViewCell : ObservationEditTableViewCell
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;

@end

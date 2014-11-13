//
//  PickerTableViewCell.h
//  MAGE
//
//  Created by Dan Barela on 11/12/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationEditTableViewCell.h"

@interface PickerTableViewCell : ObservationEditTableViewCell <UIPickerViewDataSource, UIPickerViewDelegate>

@property (strong, nonatomic) IBOutlet UIPickerView *picker;
@property (strong, nonatomic) NSMutableArray *pickerValues;

@end

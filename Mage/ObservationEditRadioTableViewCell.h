//
//  ObservationEditRadioTableViewCell.h
//  MAGE
//
//  Created by William Newman on 6/6/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationEditTableViewCell.h"

@interface ObservationEditRadioTableViewCell : ObservationEditTableViewCell <UIPickerViewDataSource, UIPickerViewDelegate>

@property (strong, nonatomic) IBOutlet UITextField *valueTextField;
@property (strong, nonatomic) IBOutlet UIPickerView *picker;
@property (strong, nonatomic) NSMutableArray *pickerValues;

@end

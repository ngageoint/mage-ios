//
//  ObservationPickerTableViewCell.h
//  Mage
//
//  Created by Dan Barela on 8/20/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationEditTableViewCell.h"

@interface ObservationPickerTableViewCell : ObservationEditTableViewCell <UIPickerViewDataSource, UIPickerViewDelegate>

@property (strong, nonatomic) IBOutlet UIPickerView *picker;
@property (strong, nonatomic) NSMutableArray *pickerValues;

@end

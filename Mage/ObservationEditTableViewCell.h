//
//  ObservationEditTableViewCell.h
//  Mage
//
//  Created by Dan Barela on 8/19/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Observation.h>
#import "ObservationEditListener.h"

@interface ObservationEditTableViewCell : UITableViewCell <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *valueTextField;
@property (weak, nonatomic) IBOutlet UILabel *keyLabel;
@property (weak, nonatomic) NSDictionary *fieldDefinition;
@property (nonatomic, weak) id<ObservationEditListener> delegate;

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation;
- (CGFloat) getCellHeightForValue: (id) value;
- (void) selectRow;

@end

//
//  ObservationEditTableViewCell.h
//  Mage
//
//  Created by Dan Barela on 8/19/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Observation.h>

@interface ObservationEditTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UITextField *valueTextField;
@property (weak, nonatomic) IBOutlet UILabel *keyLabel;
@property (weak, nonatomic) NSDictionary *fieldDefinition;

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation;
- (CGFloat) getCellHeightForValue: (id) value;
- (void) selectRow;

@end

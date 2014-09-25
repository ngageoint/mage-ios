//
//  ObservationCheckboxTableViewCell.h
//  MAGE
//
//  Created by Dan Barela on 9/25/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationEditTableViewCell.h"

@interface ObservationCheckboxTableViewCell : ObservationEditTableViewCell

@property (weak, nonatomic) IBOutlet UISwitch *checkboxSwitch;

@end

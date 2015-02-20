//
//  ObservationCheckboxViewTableViewCell.h
//  MAGE
//
//  Created by Dan Barela on 2/20/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationPropertyTableViewCell.h"

@interface ObservationCheckboxViewTableViewCell : ObservationPropertyTableViewCell

@property (weak, nonatomic) IBOutlet UISwitch *checkboxSwitch;

@end

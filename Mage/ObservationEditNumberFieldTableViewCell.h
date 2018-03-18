//
//  ObservationEditNumberFieldTableViewCell.h
//  MAGE
//
//  Created by William Newman on 4/10/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationEditTableViewCell.h"

@import SkyFloatingLabelTextField;

@interface ObservationEditNumberFieldTableViewCell : ObservationEditTableViewCell
@property (weak, nonatomic) IBOutlet SkyFloatingLabelTextFieldWithIcon *textField;
@end

//
//  ObservationStatusErrorTableViewCell.h
//  MAGE
//
//  Created by William Newman on 4/19/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObservationHeaderTableViewCell.h"

@interface ObservationStatusErrorTableViewCell : ObservationHeaderTableViewCell
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;

@end

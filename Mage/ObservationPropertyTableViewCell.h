//
//  ObservationPropertyTableViewCell.h
//  Mage
//
//  Created by Dan Barela on 7/18/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ObservationPropertyTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *keyLabel;
@property (weak, nonatomic) IBOutlet UILabel *valueLabel;

@end

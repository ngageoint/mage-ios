//
//  ObservationTableViewCell.h
//  Mage
//
//  Created by Dan Barela on 7/17/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Observation.h>

@interface ObservationTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *primaryField;
@property (weak, nonatomic) IBOutlet UILabel *variantField;
@property (weak, nonatomic) IBOutlet UILabel *timeField;
@property (weak, nonatomic) IBOutlet UILabel *userField;
@property (weak, nonatomic) IBOutlet UIImageView *icon;

- (void) populateCellWithObservation:(Observation *) observation;

@end

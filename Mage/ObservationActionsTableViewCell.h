//
//  ObservationActionsTableViewCell.h
//  MAGE
//
//  Created by William Newman on 9/26/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObservationHeaderTableViewCell.h"
#import "ObservationActionsDelegate.h"

@class ObservationActionsTableViewCell;

@interface ObservationActionsTableViewCell : ObservationHeaderTableViewCell
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;
@property (strong, nonatomic) id<ObservationActionsDelegate> observationActionsDelegate;
@end

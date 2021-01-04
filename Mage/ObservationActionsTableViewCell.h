//
//  ObservationActionsTableViewCell.h
//  MAGE
//
//  Created by William Newman on 9/26/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObservationHeaderTableViewCell.h"
#import "ObservationActionsDelegate_legacy.h"

@class ObservationActionsTableViewCell;

@interface ObservationActionsTableViewCell : ObservationHeaderTableViewCell
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;
@property (weak, nonatomic) id<ObservationActionsDelegate_legacy> observationActionsDelegate;
@end

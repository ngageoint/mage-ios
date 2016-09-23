//
//  ObservationActionsTableViewCell.h
//  MAGE
//
//  Created by William Newman on 9/26/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObservationHeaderTableViewCell.h"

@class ObservationActionsTableViewCell;

@protocol ObservationActionsDelegate <NSObject>

@required
- (void) observationFavoriteChanged;
- (void) observationShareTapped;

@end

@interface ObservationActionsTableViewCell : ObservationHeaderTableViewCell
@property (weak, nonatomic) IBOutlet UIButton *favoriteButton;
@property (weak, nonatomic) IBOutlet NSObject<ObservationActionsDelegate> *observationActionsDelegate;
@end

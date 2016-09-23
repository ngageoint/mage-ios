//
//  ObservationFavoritesTableViewCell.h
//  MAGE
//
//  Created by William Newman on 9/26/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ObservationHeaderTableViewCell.h"

@interface ObservationFavoritesTableViewCell : ObservationHeaderTableViewCell
@property (weak, nonatomic) IBOutlet UILabel *favoriteCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *favoriteTextLabel;
@end

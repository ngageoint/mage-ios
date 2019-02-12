//
//  BasicToggleTableViewCell.h
//  MAGE
//
//  Created by William Newman on 2/8/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RightDetailSubtitleTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UILabel *subtitle;
@property (weak, nonatomic) IBOutlet UILabel *detail;
@end

NS_ASSUME_NONNULL_END

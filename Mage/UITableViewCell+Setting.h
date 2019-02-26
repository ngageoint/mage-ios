//
//  UITableViewCell+Setting.h
//  MAGE
//
//  Created by William Newman on 2/7/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UITableViewCell (Setting)
@property (nonatomic, assign) NSNumber *type;
@property (nonatomic, weak) id info;
@end

NS_ASSUME_NONNULL_END

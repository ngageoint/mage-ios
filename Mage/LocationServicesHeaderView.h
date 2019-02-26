//
//  LocationServicesHeaderView.h
//  MAGE
//
//  Created by William Newman on 2/5/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LocationServicesDelegate
- (void) openSettingsTapped;
@end

@interface LocationServicesHeaderView : UIView
@property (weak, nonatomic) IBOutlet UIButton *openSettingsTapped;
@property (weak, nonatomic) IBOutlet UILabel *settingsLabel;
@property (weak, nonatomic) id<LocationServicesDelegate> delegate;
@end

NS_ASSUME_NONNULL_END

//
//  FeatureDetailViewController.h
//  MAGE
//
//  Created by William Newman on 1/16/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FeatureDetailCoordinator.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FeatureDetailControllerDelegate
- (void) onDismiss;
@end

@interface FeatureDetailViewController : UIViewController<UIPopoverControllerDelegate, UIPopoverPresentationControllerDelegate>

@property (strong, nonatomic) NSString *detail;
@property (weak, nonatomic) id<FeatureDetailControllerDelegate> delegate;

@end

NS_ASSUME_NONNULL_END

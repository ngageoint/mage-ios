//
//  FormDefaultsSectionHeader.h
//  MAGE
//
//  Created by William Newman on 2/4/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol FormDefaultsSectionHeaderDelegate
- (void) onResetDefaultsTapped;
@end

@interface FormDefaultsSectionHeader : UIView
@property (weak, nonatomic) IBOutlet UILabel *headerLabel;
@property (weak, nonatomic) IBOutlet UIButton *resetButton;

@property (weak, nonatomic) id<FormDefaultsSectionHeaderDelegate> delegate;
@end

NS_ASSUME_NONNULL_END

//
//  UINavigationItem+Subtitle.h
//  MAGE
//
//  Created by William Newman on 5/12/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
@import MaterialComponents;

@interface UINavigationItem (Subtitle)

@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *subtitleLabel;

- (void) setTitle:(NSString *) title subtitle:(nullable NSString *) subtitle scheme:(id<MDCContainerScheming>)containerScheme;

@end

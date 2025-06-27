//
//  UINavigationItem+Subtitle.m
//  MAGE
//
//  Created by William Newman on 5/12/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "UINavigationItem+Subtitle.h"
#import <objc/runtime.h>
#import "MAGE-Swift.h"

@implementation UINavigationItem (Subtitle)

- (UILabel *) subtitleLabel {
    return objc_getAssociatedObject(self, @selector(subtitleLabel));
}

- (void) setSubtitleLabel:(UILabel *)subtitleLabel {
    objc_setAssociatedObject(self, @selector(subtitleLabel), subtitleLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UILabel *) titleLabel {
    return objc_getAssociatedObject(self, @selector(titleLabel));
}

- (void) setTitleLabel:(UILabel *)titleLabel {
    objc_setAssociatedObject(self, @selector(titleLabel), titleLabel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void) setTitle:(NSString *) title subtitle:(nullable NSString *) subtitle scheme:(id<AppContainerScheming>)containerScheme {
    if ([subtitle length] == 0) {
        self.title = title;
        self.titleView = nil;
        return;
    }
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    self.titleLabel.backgroundColor = [UIColor clearColor];
    self.titleLabel.textColor = containerScheme.colorScheme.onSecondaryColor;
    self.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.titleLabel.text = title;
    [self.titleLabel sizeToFit];
    
    self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 22, 0, 0)];
    self.subtitleLabel.backgroundColor = [UIColor clearColor];
    self.subtitleLabel.textColor = [containerScheme.colorScheme.onSecondaryColor colorWithAlphaComponent:0.87];
    
    self.subtitleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
    self.subtitleLabel.text = subtitle;
    [self.subtitleLabel sizeToFit];
    
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MAX(self.titleLabel.frame.size.width, self.subtitleLabel.frame.size.width), 30)];
    [titleView addSubview:self.titleLabel];
    [titleView addSubview:self.subtitleLabel];
    
    // Center title or subtitle on screen (depending on which is larger)
    if (self.titleLabel.frame.size.width >= self.subtitleLabel.frame.size.width) {
        CGRect adjustment = self.subtitleLabel.frame;
        adjustment.origin.x = titleView.frame.origin.x + (titleView.frame.size.width/2) - (self.subtitleLabel.frame.size.width/2);
        self.subtitleLabel.frame = adjustment;
    } else {
        CGRect adjustment = self.titleLabel.frame;
        adjustment.origin.x = titleView.frame.origin.x + (titleView.frame.size.width/2) - (self.titleLabel.frame.size.width/2);
        self.titleLabel.frame = adjustment;
    }
    
    self.titleView = titleView;
}

@end

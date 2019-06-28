//
//  UINavigationItem+Subtitle.m
//  MAGE
//
//  Created by William Newman on 5/12/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "UINavigationItem+Subtitle.h"
#import "Theme+UIResponder.h"

@implementation UINavigationItem (Subtitle)

- (void) setTitle:(NSString *) title subtitle:(NSString *) subtitle {
    if ([subtitle length] == 0) {
        self.title = title;
        self.titleView = nil;
        return;
    }
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor navBarPrimaryText];
    titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    titleLabel.text = title;
    [titleLabel sizeToFit];
    
    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 22, 0, 0)];
    subtitleLabel.backgroundColor = [UIColor clearColor];
    subtitleLabel.textColor = [UIColor navBarSecondaryText];
    
    subtitleLabel.font = [UIFont systemFontOfSize:11 weight:UIFontWeightRegular];
    subtitleLabel.text = subtitle;
    [subtitleLabel sizeToFit];
    
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MAX(titleLabel.frame.size.width, subtitleLabel.frame.size.width), 30)];
    [titleView addSubview:titleLabel];
    [titleView addSubview:subtitleLabel];
    
    // Center title or subtitle on screen (depending on which is larger)
    if (titleLabel.frame.size.width >= subtitleLabel.frame.size.width) {
        CGRect adjustment = subtitleLabel.frame;
        adjustment.origin.x = titleView.frame.origin.x + (titleView.frame.size.width/2) - (subtitleLabel.frame.size.width/2);
        subtitleLabel.frame = adjustment;
    } else {
        CGRect adjustment = titleLabel.frame;
        adjustment.origin.x = titleView.frame.origin.x + (titleView.frame.size.width/2) - (titleLabel.frame.size.width/2);
        titleLabel.frame = adjustment;
    }
    
    self.titleView = titleView;
}

@end

//
//  EventTableHeaderView.m
//  MAGE
//
//  Created by Dan Barela on 4/23/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "EventTableHeaderView.h"

@interface EventTableHeaderView()

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) UILabel *label;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@end

@implementation EventTableHeaderView

- (instancetype) initWithName:(NSString *)name containerScheme:(id<MDCContainerScheming>)containerScheme {
    if (self = [super initWithFrame:CGRectMake(0, 0, 320, 45)]) {
        self.preservesSuperviewLayoutMargins = YES;
        self.name = name;
        self.label = [[UILabel alloc] initWithFrame:CGRectMake(16, 10, 320, 35)];
        [self.label setFont:[UIFont systemFontOfSize:14]];
        [self.label setText: name];
        [self addSubview:self.label];
        
        self.label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin;
        
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.label attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeft multiplier:1.0f constant:16.0f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.label attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeRight multiplier:1.0f constant:16.0f]];
        [self addConstraint:[NSLayoutConstraint constraintWithItem:self.label attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.0f]];
    }
    [self applyThemeWithContainerScheme:containerScheme];
    return self;
}

- (void) safeAreaInsetsDidChange {
    [self setFrame:CGRectMake(self.superview.safeAreaInsets.left, self.superview.safeAreaInsets.top, self.superview.bounds.size.width - self.superview.safeAreaInsets.left - self.superview.safeAreaInsets.right, 45)];
}

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }
    self.backgroundColor = containerScheme.colorScheme.surfaceColor;
    self.label.textColor = [containerScheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
}

@end

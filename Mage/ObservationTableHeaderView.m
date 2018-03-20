//
//  ObservationTableHeaderView.m
//  MAGE
//
//  Created by Dan Barela on 3/8/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationTableHeaderView.h"
#import "Theme+UIResponder.h"

@interface ObservationTableHeaderView()

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) UILabel *label;

@end

@implementation ObservationTableHeaderView

- (instancetype) initWithName:(NSString *)name {
    if (self = [super initWithFrame:CGRectMake(0, 0, 320, 48)]) {
        self.preservesSuperviewLayoutMargins = YES;
        self.name = name;
        self.label = [[UILabel alloc] initWithFrame:CGRectMake(16, 0, 320, 48)];
        [self.label setFont:[UIFont systemFontOfSize:14]];
        [self.label setText: name];
        [self addSubview:self.label];
        [self registerForThemeChanges];
    }
    
    return self;
}

- (void) safeAreaInsetsDidChange {
    [self setFrame:CGRectMake(self.superview.safeAreaInsets.left, self.superview.safeAreaInsets.top, self.superview.bounds.size.width - self.superview.safeAreaInsets.left - self.superview.safeAreaInsets.right, 48)];
}

- (void) themeDidChange:(MageTheme)theme {
    [self setBackgroundColor:[UIColor tableBackground]];
    [self.label setTextColor:[UIColor flatButton]];
}

@end

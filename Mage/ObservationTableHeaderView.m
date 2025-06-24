//
//  ObservationTableHeaderView.m
//  MAGE
//
//  Created by Dan Barela on 3/8/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationTableHeaderView.h"

@interface ObservationTableHeaderView()

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) UILabel *label;

@end

@implementation ObservationTableHeaderView

- (instancetype) initWithName:(NSString *)name andScheme: (id<AppContainerScheming>) containerScheme {
    if (self = [super initWithFrame:CGRectMake(0, 0, 320, 45)]) {
        self.preservesSuperviewLayoutMargins = YES;
        self.name = name;
        self.label = [[UILabel alloc] initWithFrame:CGRectMake(16, 10, 320, 35)];
        [self.label setFont: containerScheme.typographyScheme.subtitle1Font];
        [self.label setText: [name uppercaseString]];
        [self addSubview:self.label];
        [self.label setTextColor:containerScheme.colorScheme.onBackgroundColor];
        [self setBackgroundColor:containerScheme.colorScheme.backgroundColor];
    }
    
    return self;
}

- (void) safeAreaInsetsDidChange {
    [self setFrame:CGRectMake(self.superview.safeAreaInsets.left, self.superview.safeAreaInsets.top, self.superview.bounds.size.width - self.superview.safeAreaInsets.left - self.superview.safeAreaInsets.right, 45)];
}

@end

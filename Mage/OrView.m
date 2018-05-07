//
//  OrView.m
//  MAGE
//
//  Created by Dan Barela on 5/2/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "OrView.h"
#import "Theme+UIResponder.h"

@interface OrView()

@property (weak, nonatomic) IBOutlet UILabel *orLabel;
@property (weak, nonatomic) IBOutlet UIView *rightLine;
@property (weak, nonatomic) IBOutlet UIView *leftLine;
@property (strong, nonatomic) IBOutlet UIView *topLevelSubview;

@end

@implementation OrView

- (void) themeDidChange:(MageTheme)theme {
    self.orLabel.textColor = [UIColor secondaryText];
    self.rightLine.backgroundColor = [UIColor secondaryText];
    self.leftLine.backgroundColor = [UIColor secondaryText];
}

- (void) didMoveToSuperview {
    [self registerForThemeChanges];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

- (CGSize)intrinsicContentSize {
    return self.topLevelSubview.frame.size;
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (void) initialize {
    [[NSBundle mainBundle] loadNibNamed:@"orView" owner:self options:nil];
    [self addSubview:self.topLevelSubview];
}

@end

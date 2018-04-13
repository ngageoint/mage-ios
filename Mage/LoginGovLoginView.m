//
//  LoginGovLoginView.m
//  MAGE
//
//  Created by Dan Barela on 4/10/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "LoginGovLoginView.h"
#import "Theme+UIResponder.h"

@interface LoginGovLoginView()

@property (strong, nonatomic) IBOutlet UIView *topLevelSubView;
@property (weak, nonatomic) IBOutlet UILabel *withLabel;
@property (weak, nonatomic) IBOutlet UIImageView *logingovImage;

@end

@implementation LoginGovLoginView

- (void) themeDidChange:(MageTheme)theme {
    if ([UIColor keyboardAppearance] == UIKeyboardAppearanceDark) {
        [self.logingovImage setImage:[UIImage imageNamed:@"logingov-white"]];
    } else {
        [self.logingovImage setImage:[UIImage imageNamed:@"logingov"]];
    }
    self.withLabel.textColor = [UIColor primaryText];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self initialize];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (void) initialize {
    [[NSBundle mainBundle] loadNibNamed:@"login-gov-authView" owner:self options:nil];
    [self addSubview:self.topLevelSubView];
}

- (IBAction)signInTapped:(id)sender {
    if (self.delegate) {
        [self.delegate signinForStrategy:self.strategy];
    }
}

- (CGSize)intrinsicContentSize {
    return self.topLevelSubView.frame.size;
}

- (void) didMoveToSuperview {
    [self registerForThemeChanges];
}

@end

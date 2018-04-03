//
//  OauthLoginView.m
//  MAGE
//
//  Created by Dan Barela on 3/30/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "OAuthLoginView.h"
#import "Theme+UIResponder.h"

@interface OAuthLoginView()

@property (weak, nonatomic) IBOutlet UIView *oauthButtonView;
@property (weak, nonatomic) IBOutlet UILabel *leftLineLabel;
@property (weak, nonatomic) IBOutlet UILabel *rightLineLabel;
@property (strong, nonatomic) IBOutlet UIView *topLevelSubView;
@property (weak, nonatomic) IBOutlet UILabel *secureIcon;
@property (weak, nonatomic) IBOutlet UILabel *loginTypeLabel;


@end

@implementation OAuthLoginView

- (void) themeDidChange:(MageTheme)theme {
    self.leftLineLabel.textColor = [UIColor brand];
    self.rightLineLabel.textColor = [UIColor brand];
    self.secureIcon.textColor = [UIColor secondaryText];
    self.oauthButtonView.backgroundColor = [UIColor dialog];
    self.loginTypeLabel.textColor = [UIColor secondaryText];
    [self.oauthButtonView.layer setShadowOffset:CGSizeMake(0, 1)];
    [self.oauthButtonView.layer setShadowColor:[UIColor secondaryText].CGColor];
    [self.oauthButtonView.layer setShadowOpacity:.7];
    [self.oauthButtonView.layer setShadowRadius:2];
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
    [[NSBundle mainBundle] loadNibNamed:@"OAuthLoginView" owner:self options:nil];
    [self addSubview:self.topLevelSubView];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(signin)];
    [self.oauthButtonView addGestureRecognizer:tap];
}

- (void) signin {
    if (self.delegate) {
        [self.delegate signinForStrategy:self.strategy];
    }
}

- (CGSize)intrinsicContentSize {
    return self.topLevelSubView.frame.size;
}

- (void) didMoveToSuperview {
    NSDictionary *strategyDef = [self.strategy objectForKey:@"strategy"];
    self.secureIcon.text = @"\U0000f132";
    self.loginTypeLabel.text = [NSString stringWithFormat:@"Sign in with %@", [strategyDef objectForKey:@"title"]];
    [self registerForThemeChanges];
}

@end

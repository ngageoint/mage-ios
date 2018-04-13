//
//  OauthLoginView.m
//  MAGE
//
//  Created by Dan Barela on 3/30/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "OAuthLoginView.h"
#import "Theme+UIResponder.h"

@import HexColors;

@interface OAuthLoginView()

@property (weak, nonatomic) IBOutlet UIView *oauthButtonView;
@property (strong, nonatomic) IBOutlet UIView *topLevelSubView;
@property (weak, nonatomic) IBOutlet UILabel *secureIcon;
@property (weak, nonatomic) IBOutlet UILabel *loginTypeLabel;
@property (weak, nonatomic) IBOutlet UIImageView *oauthImage;
@property (weak, nonatomic) IBOutlet UIView *oauthImageViewContainer;

@end

@implementation OAuthLoginView

- (void) themeDidChange:(MageTheme)theme {
    self.secureIcon.textColor = [UIColor secondaryText];
    
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
    if ([strategyDef objectForKey:@"icon"] != NULL) {
        NSData *data = [[NSData alloc]initWithBase64EncodedString:[strategyDef valueForKey:@"icon"] options:NSDataBase64DecodingIgnoreUnknownCharacters];
        [self.oauthImage setImage:[UIImage imageWithData:data]];
        [self.oauthImageViewContainer setHidden:NO];
    } else {
        [self.oauthImageViewContainer setHidden:YES];
    }
    if ([strategyDef objectForKey:@"buttonColor"] != NULL) {
        self.oauthButtonView.backgroundColor = [UIColor colorWithHexString:[strategyDef valueForKey:@"buttonColor"] alpha:1.0];
    } else {
        self.oauthButtonView.backgroundColor = [UIColor dialog];
    }
    if ([strategyDef objectForKey:@"textColor"] != NULL) {
        self.loginTypeLabel.textColor = [UIColor colorWithHexString:[strategyDef valueForKey:@"textColor"] alpha:1.0];
    } else {
        self.loginTypeLabel.textColor = [UIColor primaryText];
    }
    [self registerForThemeChanges];
}

@end

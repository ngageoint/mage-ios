//
//  OauthLoginView.m
//  MAGE
//
//  Created by Dan Barela on 3/30/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "OAuthLoginView.h"
#import "Theme+UIResponder.h"
#import "AuthenticationButton.h"

@import HexColors;

@interface OAuthLoginView()<AuthenticationButtonDelegate>
@property (weak, nonatomic) IBOutlet AuthenticationButton *authenticationButton;
@end

@implementation OAuthLoginView

- (void) themeDidChange:(MageTheme)theme {
    
}

- (void) onAuthenticationButtonTapped:(id) sender {
    [self.delegate signinForStrategy:self.strategy];
}

- (void) didMoveToSuperview {
    self.authenticationButton.strategy = self.strategy;
    self.authenticationButton.delegate = self;
    
    [self registerForThemeChanges];
}

@end

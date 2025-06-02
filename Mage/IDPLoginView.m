//
//  IDPButtonDelegate.m
//  MAGE
//
//  Created by Dan Barela on 3/30/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "IDPLoginView.h"
#import "AuthenticationButton.h"
#import "AuthenticationTheming.h"

@interface IDPLoginView()<AuthenticationButtonDelegate>
@property (weak, nonatomic) IBOutlet AuthenticationButton *authenticationButton;
@property (strong, nonatomic) id<AuthenticationTheming> theme;
@end

@implementation IDPLoginView

- (void) applyTheme:(id<AuthenticationTheming>)authenticationTheme {
    if (authenticationTheme != nil) {
        self.theme = authenticationTheme;
    }
    [self.authenticationButton applyTheme:authenticationTheme];
}

- (void) onAuthenticationButtonTapped:(id) sender {
    [self.delegate signinForStrategy:self.strategy];
}

- (void) didMoveToSuperview {
    self.authenticationButton.strategy = self.strategy;
    self.authenticationButton.delegate = self;
}

@end

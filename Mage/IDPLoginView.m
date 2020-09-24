//
//  IDPButtonDelegate.m
//  MAGE
//
//  Created by Dan Barela on 3/30/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "IDPLoginView.h"
#import "Theme+UIResponder.h"
#import "AuthenticationButton.h"

@import HexColors;

@interface IDPLoginView()<AuthenticationButtonDelegate>
@property (weak, nonatomic) IBOutlet AuthenticationButton *authenticationButton;
@end

@implementation IDPLoginView

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

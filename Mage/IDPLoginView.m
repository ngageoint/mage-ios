//
//  IDPButtonDelegate.m
//  MAGE
//
//  Created by Dan Barela on 3/30/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "IDPLoginView.h"
#import "AuthenticationButton.h"

@interface IDPLoginView()<AuthenticationButtonDelegate>
@property (weak, nonatomic) IBOutlet AuthenticationButton *authenticationButton;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@end

@implementation IDPLoginView

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }
    [self.authenticationButton applyThemeWithContainerScheme:containerScheme];
}

- (void) onAuthenticationButtonTapped:(id) sender {
    [self.delegate signinForStrategy:self.strategy];
}

- (void) didMoveToSuperview {
    self.authenticationButton.strategy = self.strategy;
    self.authenticationButton.delegate = self;
}

@end

//
//  OrView.m
//  MAGE
//
//  Created by Dan Barela on 5/2/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "OrView.h"
#import "AuthenticationTheming.h"

@interface OrView()

@property (weak, nonatomic) IBOutlet UILabel *orLabel;
@property (weak, nonatomic) IBOutlet UIView *rightLine;
@property (weak, nonatomic) IBOutlet UIView *leftLine;
@property (strong, nonatomic) id<AuthenticationTheming> theme;

@end

@implementation OrView

- (void) applyTheme:(id<AuthenticationTheming>)containerTheme {
    if (containerTheme != nil) {
        self.theme = containerTheme;
        self.orLabel.textColor = [self.theme.onSurfaceColor colorWithAlphaComponent:0.6];
        self.rightLine.backgroundColor = [self.theme.onSurfaceColor colorWithAlphaComponent:0.6];
        self.leftLine.backgroundColor = [self.theme.onSurfaceColor colorWithAlphaComponent:0.6];
        self.backgroundColor = [UIColor clearColor];
    }
}

@end

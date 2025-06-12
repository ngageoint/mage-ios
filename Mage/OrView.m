//
//  OrView.m
//  MAGE
//
//  Created by Dan Barela on 5/2/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "OrView.h"
#import "MAGE-Swift.h"

@interface OrView()

@property (weak, nonatomic) IBOutlet UILabel *orLabel;
@property (weak, nonatomic) IBOutlet UIView *rightLine;
@property (weak, nonatomic) IBOutlet UIView *leftLine;
@property (strong, nonatomic) (id<AppContainerScheming>)scheme;

@end

@implementation OrView

- (void) applyThemeWithScheme:(id<AppContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
        self.orLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
        self.rightLine.backgroundColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
        self.leftLine.backgroundColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
        self.backgroundColor = [UIColor clearColor];
    }
}

@end

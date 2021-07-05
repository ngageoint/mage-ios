//
//  OrView.m
//  MAGE
//
//  Created by Dan Barela on 5/2/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "OrView.h"

@interface OrView()

@property (weak, nonatomic) IBOutlet UILabel *orLabel;
@property (weak, nonatomic) IBOutlet UIView *rightLine;
@property (weak, nonatomic) IBOutlet UIView *leftLine;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;

@end

@implementation OrView

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.orLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
        self.rightLine.backgroundColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
        self.leftLine.backgroundColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    }
}

@end

//
//  ObservationViewController_iPhone.m
//  MAGE
//
//  Created by Dan Barela on 2/11/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationViewController_iPhone.h"

@implementation ObservationViewController_iPhone

-(void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CAGradientLayer *maskLayer = [CAGradientLayer layer];

    //this is the anchor point for our gradient, in our case top left. setting it in the middle (.5, .5) will produce a radial gradient. our startPoint and endPoints are based off the anchorPoint
    maskLayer.anchorPoint = CGPointZero;

    // Setting our colors - since this is a mask the color itself is irrelevant - all that matters is the alpha.
    // A clear color will completely hide the layer we're masking, an alpha of 1.0 will completely show the masked view.
    UIColor *outerColor = [UIColor colorWithWhite:1.0 alpha:.25];
    UIColor *innerColor = [UIColor colorWithWhite:1.0 alpha:1.0];

    // An array of colors that dictatates the gradient(s)
    maskLayer.colors = @[(id)outerColor.CGColor, (id)outerColor.CGColor, (id)innerColor.CGColor, (id)innerColor.CGColor];

    // These are percentage points along the line defined by our startPoint and endPoint and correspond to our colors array.
    // The gradient will shift between the colors between these percentage points.
    maskLayer.locations = @[@0.0, @0.0, @.35, @.35f];
    maskLayer.bounds = self.mapView.frame;
    UIView *view = [[UIView alloc] initWithFrame:self.mapView.frame];

    view.backgroundColor = [UIColor blackColor];

    [self.view insertSubview:view belowSubview:self.mapView];
    self.mapView.layer.mask = maskLayer;
}

@end

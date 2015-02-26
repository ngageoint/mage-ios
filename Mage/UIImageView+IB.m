//
//  UIImageView+IB.m
//  MAGE
//
//  Created by Dan Barela on 2/19/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "UIImageView+IB.h"

@implementation UIImageView (IB)

- (void) setImageRenderingMode:(UIImageRenderingMode) renderingMode {
    self.image = [self.image imageWithRenderingMode:renderingMode];
}

- (UIImageRenderingMode) imageRenderingMode {
    return self.image.renderingMode;
}

@end

//
//  UIImageView+IB.m
//  MAGE
//
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

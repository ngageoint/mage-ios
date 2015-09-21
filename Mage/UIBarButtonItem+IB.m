//
//  UIBarButtonItem+IB.m
//  MAGE
//
//

#import "UIBarButtonItem+IB.h"

@implementation UIBarButtonItem (IB)

- (void) setImageRenderingMode:(UIImageRenderingMode) renderingMode {
    self.image = [self.image imageWithRenderingMode:renderingMode];
}

- (UIImageRenderingMode) imageRenderingMode {
    return self.image.renderingMode;
}

@end

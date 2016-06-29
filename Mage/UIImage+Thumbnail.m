//
//  UIImage+Thumbnail.m
//  MAGE
//
//  Created by William Newman on 6/29/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "UIImage+Thumbnail.h"

@implementation UIImage (Thumbnail)


- (UIImage *) thumbnailWithSize:(CGSize)size {
    
    CGRect contextBounds = CGRectZero;
    contextBounds.size = size;
    
    UIImage *squareImage = [self squareImage];
    
    UIGraphicsBeginImageContextWithOptions(contextBounds.size, NO, 0.0);
    
    [squareImage drawInRect:contextBounds];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return scaledImage;
}

- (UIImage *) squareImage {
    UIImage *squareImage = nil;
    CGSize imageSize = [self size];
    
    if (imageSize.width == imageSize.height) {
        squareImage = self;
    } else {
        // Compute square crop rect
        CGFloat smallerDimension = MIN(imageSize.width, imageSize.height);
        CGRect cropRect = CGRectMake(0, 0, smallerDimension, smallerDimension);
        
        // Center the crop rect either vertically or horizontally, depending on which dimension is smaller
        if (imageSize.width <= imageSize.height) {
            cropRect.origin = CGPointMake(0, rintf((imageSize.height - smallerDimension) / 2.0));
        } else {
            cropRect.origin = CGPointMake(rintf((imageSize.width - smallerDimension) / 2.0), 0);
        }
        
        CGImageRef croppedImageRef = CGImageCreateWithImageInRect([self CGImage], cropRect);
        squareImage = [UIImage imageWithCGImage:croppedImageRef];
        CGImageRelease(croppedImageRef);
    }
    
    return squareImage;
}

@end

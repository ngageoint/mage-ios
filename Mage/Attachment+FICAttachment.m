//
//  Attachment+FICAttachment.m
//  Mage
//
//  Created by Dan Barela on 8/7/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "Attachment+FICAttachment.h"
#import <FICImageCache.h>
#import "FICUtilities.h"

#pragma mark External Definitions

NSString *const AttachmentFamily = @"AttachmentFamily";

NSString *const AttachmentSmallSquare = @"AttachmentSmallSquare";
NSString *const AttachmentLarge = @"AttachmentLarge";
CGSize const AttachmentSquareImageSize = {50, 50};

@implementation Attachment (FICAttachment)

- (NSString *)UUID {
    if ([self url] != nil) {
        CFUUIDBytes UUIDBytes = FICUUIDBytesFromMD5HashOfString([self url]);
        return FICStringWithUUIDBytes(UUIDBytes);
    } else {
        CFUUIDBytes UUIDBytes = FICUUIDBytesFromMD5HashOfString([self localPath]);
        return FICStringWithUUIDBytes(UUIDBytes);
    }
}

- (NSString *)sourceImageUUID {
    return [self UUID];
}

- (NSURL *)sourceImageURLWithFormatName:(NSString *)formatName {
    return [NSURL URLWithString: [self url]];
}

- (FICEntityImageDrawingBlock)drawingBlockForImage:(UIImage *)image withFormatName:(NSString *)formatName {
    FICEntityImageDrawingBlock drawingBlock = ^(CGContextRef context, CGSize contextSize) {
        UIImage *imageToUse = image;
        CGRect contextBounds = CGRectZero;
        contextBounds.size = contextSize;
        if ([formatName isEqualToString:AttachmentSmallSquare]) {
            CGRect cropRect = CGRectZero;
            if (image.size.width <= contextSize.width && image.size.height <= contextSize.height) {
                cropRect = CGRectMake((contextSize.width - image.size.width)/2.0, (contextSize.height - image.size.height)/2.0, contextSize.width, contextSize.height);
            } else if (image.size.width < image.size.height) {
                // portrait mode, crop off the top and bottom
                cropRect = CGRectMake(0, (image.size.height - image.size.width)/2.0, image.size.width, image.size.width);
            } else {
                // landscape, crop the sides
                cropRect = CGRectMake((image.size.width - image.size.height)/2.0, 0, image.size.height, image.size.height);
            }
            
            CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);
            
            imageToUse = [UIImage imageWithCGImage:imageRef];
            CGImageRelease(imageRef);
        }
        
        CGContextClearRect(context, contextBounds);
        UIGraphicsPushContext(context);
        [imageToUse drawInRect:contextBounds];
        UIGraphicsPopContext();
    };
    
    return drawingBlock;
}

@end

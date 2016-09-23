//
//  Attachment+FICAttachment.m
//  Mage
//
//

#import "Attachment+Thumbnail.h"
#import "Attachment.h"
#import <FICImageCache.h>
#import "FICUtilities.h"

#pragma mark External Definitions

NSString *const AttachmentFamily = @"AttachmentFamily";

NSString *const AttachmentSmallSquare = @"AttachmentSmallSquare";
NSString *const AttachmentMediumSquare = @"AttachmentMediumSquare";
CGSize const AttachmentSquareImageSize = {75, 75};
CGSize const AttachmentiPadSquareImageSize = {100, 100};

@implementation Attachment (Thumbnail)

- (NSString *) UUID {
    if ([self url] != nil) {
        CFUUIDBytes UUIDBytes = FICUUIDBytesFromMD5HashOfString([self url]);
        return FICStringWithUUIDBytes(UUIDBytes);
    } else {
        CFUUIDBytes UUIDBytes = FICUUIDBytesFromMD5HashOfString([self localPath]);
        return FICStringWithUUIDBytes(UUIDBytes);
    }
}

- (NSString *) sourceImageUUID {
    return [self UUID];
}

- (NSURL *)sourceImageURLWithFormatName:(NSString *)formatName {
    NSInteger size = [AttachmentSmallSquare isEqualToString:formatName] ? 75 : 100 * [UIScreen mainScreen].scale;
    return [self sourceURLWithSize:size];
}

- (FICEntityImageDrawingBlock)drawingBlockForImage:(UIImage *) image withFormatName:(NSString *) formatName {
    FICEntityImageDrawingBlock drawingBlock = ^(CGContextRef context, CGSize contextSize) {
        UIImage *imageToUse = image;
        CGRect contextBounds = CGRectZero;
        contextBounds.size = contextSize;
        
        CGContextClearRect(context, contextBounds);
        UIGraphicsPushContext(context);
        
        CGContextSetRGBFillColor(context, 1.0,1.0,1.0,1.0);
        CGContextFillRect(context, contextBounds);
        CGContextSaveGState(context);
        
        CGRect cropRect = CGRectZero;
        if (image.size.width <= contextSize.width && image.size.height <= contextSize.height) {
            cropRect = CGRectMake(0,
                                  0,
                                  image.size.width * image.scale,
                                  image.size.height * image.scale);
        } else if (image.size.width < image.size.height) {
            // portrait mode, crop off the top and bottom
            cropRect = CGRectMake(0, (image.size.height - image.size.width)/2.0, image.size.width, image.size.width);
        } else {
            // landscape, crop the sides
            cropRect = CGRectMake((image.size.width - image.size.height)/2.0, 0, image.size.height, image.size.height);
        }
        
        CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);
        imageToUse = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:[image imageOrientation]];

        CGImageRelease(imageRef);

        [imageToUse drawInRect:contextBounds];
        UIGraphicsPopContext();
    };
    
    return drawingBlock;
}

- (CGSize) CGSizeAspectFitWithRatio:(CGSize) aspectRatio boundingSize:(CGSize) boundingSize {
    float mW = boundingSize.width / aspectRatio.width;
    float mH = boundingSize.height / aspectRatio.height;
    if( mH < mW ) {
        boundingSize.width = boundingSize.height / aspectRatio.height * aspectRatio.width;
    } else if( mW < mH ) {
        boundingSize.height = boundingSize.width / aspectRatio.width * aspectRatio.height;
    }
    
    return boundingSize;
}

@end

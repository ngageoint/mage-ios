//
//  FICAttachment.m
//  Mage
//
//

#import "FICAttachment.h"

@implementation FICAttachment

- (NSString *)UUID {
    return [self remoteId];
}

- (NSString *)sourceImageUUID {
    return [self url];
}

- (NSURL *)sourceImageURLWithFormatName:(NSString *)formatName {
    return [NSURL URLWithString: [self url]];
}

- (FICEntityImageDrawingBlock)drawingBlockForImage:(UIImage *)image withFormatName:(NSString *)formatName {
    FICEntityImageDrawingBlock drawingBlock = ^(CGContextRef context, CGSize contextSize) {
        CGRect contextBounds = CGRectZero;
        contextBounds.size = contextSize;
        CGContextClearRect(context, contextBounds);
        
//        // Clip medium thumbnails so they have rounded corners
//        if ([formatName isEqualToString:XXImageFormatNameUserThumbnailMedium]) {
//            UIBezierPath clippingPath = [self _clippingPath];
//            [clippingPath addClip];
//        }
        
        UIGraphicsPushContext(context);
        [image drawInRect:contextBounds];
        UIGraphicsPopContext();
    };
    
    return drawingBlock;
}

@end

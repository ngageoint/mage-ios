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

@implementation Attachment (FICAttachment)

NSString *_UUID;

- (NSString *)UUID {
    
    if (_UUID == nil) {
        CFUUIDBytes UUIDBytes = FICUUIDBytesFromMD5HashOfString([self url]);
        _UUID = FICStringWithUUIDBytes(UUIDBytes);
    }
    
    return _UUID;
    
    
    return [self remoteId];
}

- (NSString *)sourceImageUUID {
    return [self UUID];
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

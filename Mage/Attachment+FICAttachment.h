//
//  Attachment+FICAttachment.h
//  Mage
//
//  Created by Dan Barela on 8/7/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "Attachment.h"
#import <FICEntity.h>

extern NSString *const AttachmentFamily;
extern NSString *const AttachmentSmallSquare;
extern NSString *const AttachmentMediumSquare;
extern NSString *const AttachmentLarge;
extern CGSize const AttachmentSquareImageSize;
extern CGSize const AttachmentiPadSquareImageSize;

@interface Attachment (FICAttachment) <FICEntity>

@end

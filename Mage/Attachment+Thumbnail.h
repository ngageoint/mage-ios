//
//  Attachment+FICAttachment.h
//  Mage
//
//

#import "Attachment.h"
#import "FICEntity.h"

extern NSString *const AttachmentFamily;

extern NSString *const AttachmentSmallSquare;
extern NSString *const AttachmentMediumSquare;
extern CGSize const AttachmentSquareImageSize;
extern CGSize const AttachmentiPadSquareImageSize;

@interface Attachment (Thumbnail) <FICEntity>

@end

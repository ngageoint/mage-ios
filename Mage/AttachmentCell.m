//
//  AttachmentCell.m
//  Mage
//
//

#import "AttachmentCell.h"
#import "FICImageCache.h"
#import "Attachment+Thumbnail.h"

@implementation AttachmentCell

- (void)prepareForReuse {
    self.imageView.image = [UIImage imageNamed:@"download_thumbnail"];
}

-(void) setImageForAttachament:(Attachment *) attachment withFormatName:(NSString *) formatName {
    self.attachment = attachment;
    
    __weak typeof(self) weakSelf = self;
    BOOL imageExists = [[FICImageCache sharedImageCache] retrieveImageForEntity:attachment withFormatName:formatName completionBlock:^(id<FICEntity> entity, NSString *formatName, UIImage *image) {
        // This completion block may be called much later, check to make sure this cell hasn't been reused for a different attachment before displaying the image that has loaded.
        if (attachment == [self attachment]) {
            weakSelf.imageView.image = image;
            weakSelf.imageView.layer.cornerRadius = 5;
            weakSelf.imageView.clipsToBounds = YES;
        }
    }];
    
    if (imageExists == NO) {
        self.imageView.image = [UIImage imageNamed:@"download_thumbnail"];
    }
}

@end

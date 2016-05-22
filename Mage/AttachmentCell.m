//
//  AttachmentCell.m
//  Mage
//
//

#import "AttachmentCell.h"
#import "FICImageCache.h"
#import "Attachment+FICAttachment.h"
#import "AppDelegate.h"

@implementation AttachmentCell

- (void)prepareForReuse {
    self.imageView.image = nil;
}

-(void) setImageForAttachament:(Attachment *) attachment {
    self.attachment = attachment;
    
    self.imageView.image = [UIImage imageNamed:@"download"];
    
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    __weak typeof(self) weakSelf = self;
    [delegate.imageCache retrieveImageForEntity:attachment withFormatName:AttachmentMediumSquare completionBlock:^(id<FICEntity> entity, NSString *formatName, UIImage *image) {
        // This completion block may be called much later, check to make sure this cell hasn't been reused for a different attachment before displaying the image that has loaded.
        if (attachment == [self attachment]) {
            weakSelf.imageView.image = image;
            [weakSelf.imageView.layer addAnimation:[CATransition animation] forKey:kCATransition];
            weakSelf.imageView.layer.cornerRadius = 5;
            weakSelf.imageView.clipsToBounds = YES;
        }
    }];
}

@end

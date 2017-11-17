//
//  ImageViewerViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "Attachment.h"

@interface AttachmentViewController : UIViewController

@property (strong, nonatomic) Attachment *attachment;
@property (strong, nonatomic) NSURL *mediaUrl;
@property (strong, nonatomic) NSString *contentType;

- (instancetype) initWithAttachment: (Attachment *) attachment;
- (instancetype) initWithMediaURL: (NSURL *) mediaURL andContentType: (NSString *) contentType andTitle: (NSString *) title;

- (void) setContent:(Attachment *) attachment;

@end

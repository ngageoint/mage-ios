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

- (void) setContent:(Attachment *) attachment;

@end

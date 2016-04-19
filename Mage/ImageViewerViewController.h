//
//  ImageViewerViewController.h
//  Mage
//
//

#import <UIKit/UIKit.h>
#import "Attachment.h"

@interface ImageViewerViewController : UIViewController

@property (weak, nonatomic) Attachment *attachment;
@property (weak, nonatomic) NSURL *mediaUrl;
@property (weak, nonatomic) NSString *contentType;

- (void) setContent:(Attachment *) attachment;

@end

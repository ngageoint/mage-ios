//
//  AttachmentCell.h
//  Mage
//
//

#import <UIKit/UIKit.h>

@class Attachment;

@interface AttachmentCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) Attachment *attachment;

-(void) setImageForAttachament:(Attachment *) attachment withFormatName:(NSString *) formatName;

@end

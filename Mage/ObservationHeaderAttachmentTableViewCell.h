//
//  ObservationHeaderAttachmentTableViewCell.h
//  MAGE
//
//

#import "ObservationHeaderTableViewCell.h"
#import "AttachmentSelectionDelegate.h"

@interface ObservationHeaderAttachmentTableViewCell : ObservationHeaderTableViewCell

@property (weak, nonatomic) IBOutlet NSObject<AttachmentSelectionDelegate> *attachmentSelectionDelegate;

@end

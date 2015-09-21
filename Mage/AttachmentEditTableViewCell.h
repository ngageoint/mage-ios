//
//  AttachmentEditTableViewCell.h
//  MAGE
//
//

#import "ObservationEditTableViewCell.h"
#import "AttachmentSelectionDelegate.h"

@interface AttachmentEditTableViewCell : ObservationEditTableViewCell
@property (weak, nonatomic) NSObject<AttachmentSelectionDelegate> *attachmentSelectionDelegate;
@end

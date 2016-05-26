//
//  AttachmentEditTableViewCell.h
//  MAGE
//
//

#import "ObservationEditTableViewCell.h"
#import "AttachmentSelectionDelegate.h"

@class AttachmentCollectionDataStore;

@interface AttachmentEditTableViewCell : ObservationEditTableViewCell
@property (weak, nonatomic) IBOutlet NSObject<AttachmentSelectionDelegate> *attachmentSelectionDelegate;
@end

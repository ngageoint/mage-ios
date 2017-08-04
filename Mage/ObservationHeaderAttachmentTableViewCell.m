//
//  ObservationHeaderAttachmentTableViewCell.m
//  MAGE
//
//

#import "ObservationHeaderAttachmentTableViewCell.h"
#import "AttachmentCollectionDataStore.h"
#import "Attachment+Thumbnail.h"

@interface ObservationHeaderAttachmentTableViewCell()
@property (strong, nonatomic) AttachmentCollectionDataStore *ads;
@property (weak, nonatomic) IBOutlet UICollectionView *attachmentCollection;
@end

@implementation ObservationHeaderAttachmentTableViewCell

- (void) configureCellForObservation:(Observation *)observation withForms:(NSArray *)forms {
    self.ads = [[AttachmentCollectionDataStore alloc] init];
    self.ads.attachmentFormatName = AttachmentSmallSquare;
    self.ads.attachmentCollection = self.attachmentCollection;
    self.attachmentCollection.delegate = self.ads;
    self.attachmentCollection.dataSource = self.ads;
    self.ads.observation = observation;
}

- (void) setAttachmentSelectionDelegate:(NSObject<AttachmentSelectionDelegate> *)attachmentSelectionDelegate {
    _attachmentSelectionDelegate = attachmentSelectionDelegate;
    self.ads.attachmentSelectionDelegate = self.attachmentSelectionDelegate;
}

@end

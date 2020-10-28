//
//  ObservationHeaderAttachmentTableViewCell.m
//  MAGE
//
//

#import "ObservationHeaderAttachmentTableViewCell.h"
#import "AttachmentCollectionDataStore.h"
#import "Theme+UIResponder.h"

@interface ObservationHeaderAttachmentTableViewCell()
@property (strong, nonatomic) AttachmentCollectionDataStore *ads;
@property (weak, nonatomic) IBOutlet UICollectionView *attachmentCollection;
@end

@implementation ObservationHeaderAttachmentTableViewCell

- (void) themeDidChange:(MageTheme)theme {
    self.backgroundColor = [UIColor dialog];
}

- (void) configureCellForObservation:(Observation *)observation withForms:(NSArray *)forms {
    [self.attachmentCollection registerNib:[UINib nibWithNibName:@"AttachmentCell" bundle:nil] forCellWithReuseIdentifier:@"AttachmentCell"];
    self.ads = [[AttachmentCollectionDataStore alloc] init];
    self.ads.attachmentCollection = self.attachmentCollection;
    self.attachmentCollection.delegate = self.ads;
    self.attachmentCollection.dataSource = self.ads;
    self.ads.attachments = [observation.attachments setByAddingObjectsFromArray: observation.transientAttachments];
    [self registerForThemeChanges];
}

- (void) setAttachmentSelectionDelegate:(NSObject<AttachmentSelectionDelegate> *)attachmentSelectionDelegate {
    _attachmentSelectionDelegate = attachmentSelectionDelegate;
    self.ads.attachmentSelectionDelegate = self.attachmentSelectionDelegate;
}

@end

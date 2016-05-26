//
//  AttachmentEditTableViewCell.m
//  MAGE
//
//

#import "AttachmentEditTableViewCell.h"
#import "AttachmentCollectionDataStore.h"
#import "Attachment+Thumbnail.h"

@interface AttachmentEditTableViewCell ()
@property (weak, nonatomic) IBOutlet UICollectionView *attachmentCollection;
@property (strong, nonatomic) AttachmentCollectionDataStore *ads;
@end

@implementation AttachmentEditTableViewCell

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    if (self.ads == nil) {
        self.ads = [[AttachmentCollectionDataStore alloc] init];
        self.ads.attachmentFormatName = AttachmentSmallSquare;
        self.ads.attachmentCollection = self.attachmentCollection;
        self.attachmentCollection.delegate = self.ads;
        self.attachmentCollection.dataSource = self.ads;
        self.ads.observation = observation;
    } else {
        [self.ads.attachmentCollection reloadData];
    }
    
    self.ads.attachmentSelectionDelegate = self.attachmentSelectionDelegate;
}

- (CGFloat) getCellHeightForValue: (id) value {
    NSNumber *number = value;
    if ([number isEqualToNumber: [NSNumber numberWithInt:0]]) {
        return 0.0;
    }
    return self.bounds.size.height;
}

@end

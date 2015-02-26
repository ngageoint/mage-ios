//
//  ObservationHeaderAttachmentTableViewCell.m
//  MAGE
//
//  Created by Dan Barela on 2/19/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationHeaderAttachmentTableViewCell.h"
#import "AttachmentCollectionDataStore.h"

@interface ObservationHeaderAttachmentTableViewCell()

@property (strong, nonatomic) AttachmentCollectionDataStore *ads;
@property (weak, nonatomic) IBOutlet UICollectionView *attachmentCollection;

@end

@implementation ObservationHeaderAttachmentTableViewCell

- (void) configureCellForObservation:(Observation *)observation {
    self.ads = [[AttachmentCollectionDataStore alloc] init];
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
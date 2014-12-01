//
//  ObservationAttachmentTableViewCell.m
//  MAGE
//
//  Created by Dan Barela on 11/20/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationAttachmentTableViewCell.h"
#import "AttachmentCollectionDataStore.h"

@interface ObservationAttachmentTableViewCell ()

@property (strong, nonatomic) AttachmentCollectionDataStore *ads;
@property (weak, nonatomic) IBOutlet UICollectionView *attachmentCollection;

@end

@implementation ObservationAttachmentTableViewCell

- (void) populateCellWithObservation:(Observation *) observation {
    [super populateCellWithObservation:observation];
    self.ads = [[AttachmentCollectionDataStore alloc] init];
    self.ads.attachmentCollection = self.attachmentCollection;
    self.attachmentCollection.delegate = self.ads;
    self.attachmentCollection.dataSource = self.ads;
    self.ads.observation = observation;
    self.ads.attachmentSelectionDelegate = self.attachmentSelectionDelegate;
}

@end

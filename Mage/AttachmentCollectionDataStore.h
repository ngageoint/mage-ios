//
//  AttachmentCollectionDataStore.h
//  MAGE
//
//  Created by Dan Barela on 11/19/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Observation+helper.h>
#import "AttachmentSelectionDelegate.h"

@interface AttachmentCollectionDataStore : NSObject <UICollectionViewDataSource, UICollectionViewDelegate>
@property (weak, nonatomic) IBOutlet UICollectionView *attachmentCollection;
@property (strong, nonatomic) Observation *observation;
@property (nonatomic, strong) IBOutlet id<AttachmentSelectionDelegate> attachmentSelectionDelegate;

@end

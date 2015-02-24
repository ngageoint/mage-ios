//
//  ObservationAttachmentTableViewCell.h
//  MAGE
//
//  Created by Dan Barela on 11/20/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ObservationTableViewCell.h"
#import "AttachmentSelectionDelegate.h"

@interface ObservationAttachmentTableViewCell : ObservationTableViewCell

@property (weak, nonatomic) IBOutlet NSObject<AttachmentSelectionDelegate> *attachmentSelectionDelegate;
@property (weak, nonatomic) IBOutlet UICollectionView *attachmentCollection;

@end

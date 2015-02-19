//
//  ObservationHeaderAttachmentTableViewCell.h
//  MAGE
//
//  Created by Dan Barela on 2/19/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationHeaderTableViewCell.h"
#import "AttachmentSelectionDelegate.h"

@interface ObservationHeaderAttachmentTableViewCell : ObservationHeaderTableViewCell

@property (weak, nonatomic) IBOutlet NSObject<AttachmentSelectionDelegate> *attachmentSelectionDelegate;

@end

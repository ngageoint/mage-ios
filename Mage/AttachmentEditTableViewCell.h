//
//  AttachmentEditTableViewCell.h
//  MAGE
//
//  Created by Dan Barela on 12/1/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationEditTableViewCell.h"
#import "AttachmentSelectionDelegate.h"

@interface AttachmentEditTableViewCell : ObservationEditTableViewCell
@property (weak, nonatomic) NSObject<AttachmentSelectionDelegate> *attachmentSelectionDelegate;
@end

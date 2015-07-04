//
//  AttachmentSelectionDelegate.h
//  MAGE
//
//  Created by Dan Barela on 11/20/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "Attachment.h"

@protocol AttachmentSelectionDelegate <NSObject>

@required

- (void) selectedAttachment:(Attachment *) attachment;

@end
//
//  AttachmentViewCoordinator.h
//  MAGE
//
//  Created by Daniel Barela on 3/10/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Attachment.h"
#import "MAGE-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AttachmentViewDelegate <NSObject>

- (void) doneViewing: (NSObject *) coordinator;

@end

@interface AttachmentViewCoordinator : NSObject <AskToDownloadDelegate>

- (instancetype) initWithNavigationController: (UINavigationController *) navigationController andDelegate: (id<AttachmentViewDelegate>) delegate andAttachment: (Attachment *) attachment;
- (void) start;

@end

NS_ASSUME_NONNULL_END

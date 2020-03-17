//
//  AskToDownloadViewController.h
//  MAGE
//
//  Created by Daniel Barela on 3/11/20.
//  Copyright © 2020 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Attachment.h"

NS_ASSUME_NONNULL_BEGIN

@protocol AskToDownloadDelegate <NSObject>

- (void) downloadAttachment;

@end

@interface AskToDownloadViewController : UIViewController

- (instancetype) initWithAttachment: (Attachment *) attachment andDelegate: (id<AskToDownloadDelegate>) delegate;
@end

NS_ASSUME_NONNULL_END

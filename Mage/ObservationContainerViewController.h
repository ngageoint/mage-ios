//
//  ObservationContainerViewController.h
//  MAGE
//
//  Created by William Newman on 7/3/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AttachmentSelectionDelegate.h"
#import "ObservationSelectionDelegate.h"

@interface ObservationContainerViewController : UIViewController

@property (strong, nonatomic) id<AttachmentSelectionDelegate, ObservationSelectionDelegate> delegate;

@end

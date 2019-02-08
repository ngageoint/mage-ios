//
//  EventInformationController.h
//  MAGE
//
//  Created by William Newman on 1/29/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Event+CoreDataProperties.h"

NS_ASSUME_NONNULL_BEGIN

@protocol EventInformationControllerDelegate
- (void) formSelected:(NSDictionary *) form;
@end

@interface EventInformationController : UITableViewController

@property (weak, nonatomic) id<EventInformationControllerDelegate> delegate;
@property (weak, nonatomic) Event* event;

@end

NS_ASSUME_NONNULL_END

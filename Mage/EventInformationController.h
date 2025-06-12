//
//  EventInformationController.h
//  MAGE
//
//  Created by William Newman on 1/29/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppContainerScheming.h"
#import "MAGE-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@protocol EventInformationControllerDelegate
- (void) formSelected:(Form *) form;
@end

@interface EventInformationController : UITableViewController

@property (strong, nonatomic) id<EventInformationControllerDelegate> delegate;
@property (strong, nonatomic) Event* event;

- (instancetype) initWithScheme: (id<AppContainerScheming>) containerScheme;

@end

NS_ASSUME_NONNULL_END

//  FormDefaultsCoordinator.h
//  MAGE
//
//  Created by William Newman on 1/30/19.
//  Copyright © 2019 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FormDefaultsTableViewController.h"
#import "Event.h"

NS_ASSUME_NONNULL_BEGIN

@protocol FormDefaultsDelegate
- (void) formDefaultsComplete:(id) coordinator;
@end

@interface FormDefaultsCoordinator : NSObject

@property (weak, nonatomic) id<FormDefaultsDelegate> delegate;

- (instancetype) initWithViewController: (UINavigationController *) viewController event: (Event *) event form:(NSDictionary *) form;
- (void) start;

@end

NS_ASSUME_NONNULL_END

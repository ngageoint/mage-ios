//
//  EventChooserCoordinator.h
//  MAGE
//
//  Created by Dan Barela on 9/7/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Event.h>
#import <Form.h>

@protocol EventChooserDelegate

- (void) eventChoosen: (Event *) event;

@end

@interface EventChooserCoordinator : NSObject

- (instancetype) initWithViewController: (UIViewController *) viewController andDelegate: (id<EventChooserDelegate>) delegate;
- (void) start;

@end

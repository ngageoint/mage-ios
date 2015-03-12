//
//  Event+helper.h
//  mage-ios-sdk
//
//  Created by Dan Barela on 3/2/15.
//  Copyright (c) 2015 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Event.h"
#import "User.h"

@interface Event (helper)

extern NSString * const MAGEEventsFetched;
+ (NSOperation *) operationToFetchEventsWithSuccess: (void (^)()) success failure: (void (^)(NSError *)) failure;
+ (void) sendRecentEvent;
+ (Event *) getCurrentEvent;
- (BOOL) isUserInEvent: (User *) user;

@end

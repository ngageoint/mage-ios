//
//  NotificationRequester.h
//  Pods
//
//  Created by Dan Barela on 8/30/17.
//
//

#import <Foundation/Foundation.h>

@class Observation;
@class Event;

@interface NotificationRequester : NSObject

+ (void) observationPulled: (Observation *) observation;
+ (void) sendBulkNotificationCount: (NSUInteger) count inEvent: (Event *) event;

@end

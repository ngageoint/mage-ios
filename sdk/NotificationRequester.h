//
//  NotificationRequester.h
//  Pods
//
//  Created by Dan Barela on 8/30/17.
//
//

#import <Foundation/Foundation.h>
#import "Observation.h"
#import "Event.h"

@interface NotificationRequester : NSObject

+ (void) observationPulled: (Observation *) observation;
+ (void) sendBulkNotificationCount: (NSUInteger) count inEvent: (Event *) event;

@end

//
//  NotificationRequester.h
//  Pods
//
//  Created by Dan Barela on 8/30/17.
//
//

#import <Foundation/Foundation.h>

@interface NotificationRequester : NSObject

+ (void) observationPulled: (NSManagedObject *) observation;
+ (void) sendBulkNotificationCount: (NSUInteger) count inEvent: (NSManagedObject *) event;

@end

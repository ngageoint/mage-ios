//
//  Event+helper.h
//  mage-ios-sdk
//
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

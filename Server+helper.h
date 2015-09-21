//
//  Server+helper.h
//  mage-ios-sdk
//
//

#import "Server.h"

@interface Server (helper)

+(NSString *) serverUrl;
+(void) setServerUrl:(NSString *) serverUrl;
+(NSNumber *) currentEventId;
+(void) setCurrentEventId:(NSNumber *) eventId;

@end

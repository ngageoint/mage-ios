//
//  Server+helper.h
//  mage-ios-sdk
//
//  Created by William Newman on 10/22/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Server.h"

@interface Server (helper)

+(NSString *) serverUrl;
+(void) setServerUrl:(NSString *) serverUrl;
+(NSNumber *) currentEventId;
+(void) setCurrentEventId:(NSNumber *) eventId;

@end

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

+(NSNumber *) observationLayerId;
+(void) setObservationLayerId:(NSNumber *) observationLayerId;

+(NSString *) observationFormId;
+(void) setObservationFormId:(NSString *) observationFormId;

+(NSDictionary *) observationForm;
+(void) setObservationForm:(NSDictionary *) observationForm;

@end

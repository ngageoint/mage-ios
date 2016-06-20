//
//  Server.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Server.h"

@implementation Server

+(NSString *) serverUrl {
    return [Server getPropertyForKey:@"serverUrl"];
}

+(void) setServerUrl:(NSString *) serverUrl {
    [Server setProperty:serverUrl forKey:@"serverUrl"];
}

+(NSNumber *) currentEventId {
    return [Server getPropertyForKey:@"currentEventId"];
}

+(void) setCurrentEventId: (NSNumber *) eventId {
    [Server setProperty:eventId forKey:@"currentEventId"];
}

+(id) getPropertyForKey:(NSString *) key {
    Server *server = [Server MR_findFirst];
    
    id property = nil;
    if (server) {
        NSDictionary *properties = server.properties;
        property = [properties objectForKey:key];
    }
    
    return property;
}

+(void) setProperty:(id) property forKey:(NSString *) key {
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        Server *server = [Server MR_findFirstInContext:localContext];
        if (server) {
            NSMutableDictionary *properties = [server.properties mutableCopy];
            [properties setObject:property forKey:key];
            server.properties = properties;
        } else {
            server = [Server MR_createEntityInContext:localContext];
            server.properties = @{key: property};
        }
    }];
}

@end

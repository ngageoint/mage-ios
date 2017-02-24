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

+ (void) setServerUrl:(NSString *) serverUrl {
    [Server setServerUrl:serverUrl completion:nil];
}

+ (void) setServerUrl:(NSString *) serverUrl completion:(nullable void (^)(BOOL contextDidSave, NSError * _Nullable error)) completion {
    [Server setProperty:serverUrl forKey:@"serverUrl" completion:completion];
}

+ (NSNumber *) currentEventId {
    return [Server getPropertyForKey:@"currentEventId"];
}

+ (void) setCurrentEventId: (NSNumber *) eventId {
    [Server setCurrentEventId:eventId completion:nil];
}

+ (void) setCurrentEventId: (NSNumber *) eventId completion:(nullable void (^)(BOOL contextDidSave, NSError * _Nullable error)) completion {
    [Server setProperty:eventId forKey:@"currentEventId" completion:completion];
}

+ (id) getPropertyForKey:(NSString *) key {
    Server *server = [Server MR_findFirst];
    
    id property = nil;
    if (server) {
        NSDictionary *properties = server.properties;
        property = [properties objectForKey:key];
    }
    
    return property;
}

+ (void) setProperty:(id) property forKey:(NSString *) key completion:(void (^)(BOOL contextDidSave, NSError * _Nullable error)) completion {
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
        Server *server = [Server MR_findFirstInContext:localContext];
        if (server) {
            NSMutableDictionary *properties = [server.properties mutableCopy];
            [properties setObject:property forKey:key];
            server.properties = properties;
        } else {
            server = [Server MR_createEntityInContext:localContext];
            server.properties = @{key: property};
        }
    } completion:^(BOOL contextDidSave, NSError * _Nullable error) {
        if (completion) {
            completion(contextDidSave, error);
        }
    }];
}

@end

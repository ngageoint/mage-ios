//
//  Server.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Server.h"
#import "MageSessionManager.h"

NSString * const kCurrentEventIdKey = @"currentEventId";

@implementation Server

// TODO Move, not really stored in database
+ (NSNumber *) currentEventId {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kCurrentEventIdKey];
}

+ (void) setCurrentEventId: (NSNumber *) eventId {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self raiseEventTaskPriorities:eventId];
    });
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:eventId forKey:kCurrentEventIdKey];
    [defaults synchronize];
}

+ (NSString *) serverUrl {
    return [Server getPropertyForKey:@"serverUrl" inManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
}

+ (void) setServerUrl:(NSString *) serverUrl {
    [Server setServerUrl:serverUrl completion:nil];
}

+ (void) setServerUrl:(NSString *) serverUrl completion:(nullable void (^)(BOOL contextDidSave, NSError * _Nullable error)) completion {
    [Server setProperty:serverUrl forKey:@"serverUrl" completion:completion];
}

+ (void) raiseEventTaskPriorities: (NSNumber *) eventId {
    if (eventId != nil) {
        NSDictionary<NSNumber *, NSArray<NSNumber *> *> *eventTasks = [MageSessionManager eventTasks];
        if (eventTasks != nil) {
            NSArray<NSNumber *> *tasks = [eventTasks objectForKey:eventId];
            if (tasks != nil) {
                MageSessionManager *manager = [MageSessionManager manager];
                for (NSNumber *taskIdentifier in tasks) {
                    [manager readdTaskWithIdentifier:[taskIdentifier unsignedIntegerValue] withPriority:NSURLSessionTaskPriorityHigh];
                }
            }
        }
    }
}

+ (id) getPropertyForKey:(NSString *) key inManagedObjectContext:(NSManagedObjectContext *) context {
    Server *server = [Server MR_findFirstInContext:context];
    
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

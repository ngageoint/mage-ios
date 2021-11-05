//
//  Server.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

import Foundation
import CoreData
import MagicalRecord

@objc public class Server: NSManagedObject {
    
    @objc public static func serverUrl() -> String? {
        return Server.getPropertyForKey(key: "serverUrl", context: NSManagedObjectContext.mr_default()) as? String
    }
    
    @objc public static func setServerUrl(serverUrl: String, completion: MRSaveCompletionHandler? = nil) {
        Server.setProperty(property: serverUrl, key: "serverUrl", completion: completion)
    }
    
    @objc public static func currentEventId() -> NSNumber? {
        return UserDefaults.standard.currentEventId as? NSNumber
        //    return [[NSUserDefaults standardUserDefaults] objectForKey:kCurrentEventIdKey];
    }
    
    @objc public static func setCurrentEventId(_ eventId: NSNumber) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.raiseEventTaskPriorities(eventId: eventId);
        }
        
        UserDefaults.standard.currentEventId = eventId;
    }
    
    @objc public static func removeCurrentEventId() {
        UserDefaults.standard.currentEventId = nil;
    }
    
    static func getPropertyForKey(key: String, context: NSManagedObjectContext) -> Any? {
        if let server = Server.mr_findFirst(in: context), let properties = server.properties {
            return properties[key];
        }
        return nil;
    }
    
    static func setProperty(property: Any, key: String, completion: MRSaveCompletionHandler? = nil) {
        MagicalRecord.save({ localContext in
            if let server = Server.mr_findFirst(in: localContext) as? Server {
                var properties = server.properties;
            }
        }, completion: completion);
        //    [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
        //        Server *server = [Server MR_findFirstInContext:localContext];
        //        if (server) {
        //            NSMutableDictionary *properties = [server.properties mutableCopy];
        //            [properties setObject:property forKey:key];
        //            server.properties = properties;
        //        } else {
        //            server = [Server MR_createEntityInContext:localContext];
        //            server.properties = @{key: property};
        //        }
        //    } completion:^(BOOL contextDidSave, NSError * _Nullable error) {
        //        if (completion) {
        //            completion(contextDidSave, error);
        //        }
        //    }];
    }
    
    static func raiseEventTaskPriorities(eventId: NSNumber) {
        
    }
    //+ (void) raiseEventTaskPriorities: (NSNumber *) eventId {
    //    if (eventId != nil) {
    //        NSDictionary<NSNumber *, NSArray<NSNumber *> *> *eventTasks = [MageSessionManager eventTasks];
    //        if (eventTasks != nil) {
    //            NSArray<NSNumber *> *tasks = [eventTasks objectForKey:eventId];
    //            if (tasks != nil) {
    //                MageSessionManager *manager = [MageSessionManager sharedManager];
    //                for (NSNumber *taskIdentifier in tasks) {
    //                    [manager readdTaskWithIdentifier:[taskIdentifier unsignedIntegerValue] withPriority:NSURLSessionTaskPriorityHigh];
    //                }
    //            }
    //        }
    //    }
    //}
    
    //+ (id) getPropertyForKey:(NSString *) key inManagedObjectContext:(NSManagedObjectContext *) context {
    //    Server *server = [Server MR_findFirstInContext:context];
    //
    //    id property = nil;
    //    if (server) {
    //        NSDictionary *properties = server.properties;
    //        property = [properties objectForKey:key];
    //    }
    //
    //    return property;
    //}
    //
    //+ (void) setProperty:(id) property forKey:(NSString *) key completion:(void (^)(BOOL contextDidSave, NSError * _Nullable error)) completion {
    //    [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
    //        Server *server = [Server MR_findFirstInContext:localContext];
    //        if (server) {
    //            NSMutableDictionary *properties = [server.properties mutableCopy];
    //            [properties setObject:property forKey:key];
    //            server.properties = properties;
    //        } else {
    //            server = [Server MR_createEntityInContext:localContext];
    //            server.properties = @{key: property};
    //        }
    //    } completion:^(BOOL contextDidSave, NSError * _Nullable error) {
    //        if (completion) {
    //            completion(contextDidSave, error);
    //        }
    //    }];
    //}
}

//extern NSString * const kCurrentEventIdKey;
//
//@interface Server : NSManagedObject
//
//+ (NSString *) serverUrl;
//+ (void) setServerUrl:(NSString *) serverUrl;
//+ (void) setServerUrl:(NSString *) serverUrl completion:(nullable void (^)(BOOL contextDidSave, NSError * _Nullable error)) completion;
//
//+ (NSNumber *) currentEventId;
//+ (void) setCurrentEventId:(NSNumber *) eventId;
//+ (void) removeCurrentEventId;
//
//#import "Server.h"
//#import "MageSessionManager.h"
//
//NSString * const kCurrentEventIdKey = @"currentEventId";
//
//@implementation Server
//
//// TODO Move, not really stored in database
//+ (NSNumber *) currentEventId {
//    return [[NSUserDefaults standardUserDefaults] objectForKey:kCurrentEventIdKey];
//}
//
//+ (void) setCurrentEventId: (NSNumber *) eventId {
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [self raiseEventTaskPriorities:eventId];
//    });
//
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults setObject:eventId forKey:kCurrentEventIdKey];
//    [defaults synchronize];
//}
//
//+ (void) removeCurrentEventId {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    [defaults removeObjectForKey:kCurrentEventIdKey];
//    [defaults synchronize];
//}
//
//+ (NSString *) serverUrl {
//    return [Server getPropertyForKey:@"serverUrl" inManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
//}
//
//+ (void) setServerUrl:(NSString *) serverUrl {
//    [Server setServerUrl:serverUrl completion:nil];
//}
//
//+ (void) setServerUrl:(NSString *) serverUrl completion:(nullable void (^)(BOOL contextDidSave, NSError * _Nullable error)) completion {
//    [Server setProperty:serverUrl forKey:@"serverUrl" completion:completion];
//}
//
//+ (void) raiseEventTaskPriorities: (NSNumber *) eventId {
//    if (eventId != nil) {
//        NSDictionary<NSNumber *, NSArray<NSNumber *> *> *eventTasks = [MageSessionManager eventTasks];
//        if (eventTasks != nil) {
//            NSArray<NSNumber *> *tasks = [eventTasks objectForKey:eventId];
//            if (tasks != nil) {
//                MageSessionManager *manager = [MageSessionManager sharedManager];
//                for (NSNumber *taskIdentifier in tasks) {
//                    [manager readdTaskWithIdentifier:[taskIdentifier unsignedIntegerValue] withPriority:NSURLSessionTaskPriorityHigh];
//                }
//            }
//        }
//    }
//}
//
//+ (id) getPropertyForKey:(NSString *) key inManagedObjectContext:(NSManagedObjectContext *) context {
//    Server *server = [Server MR_findFirstInContext:context];
//
//    id property = nil;
//    if (server) {
//        NSDictionary *properties = server.properties;
//        property = [properties objectForKey:key];
//    }
//
//    return property;
//}
//
//+ (void) setProperty:(id) property forKey:(NSString *) key completion:(void (^)(BOOL contextDidSave, NSError * _Nullable error)) completion {
//    [MagicalRecord saveWithBlock:^(NSManagedObjectContext * _Nonnull localContext) {
//        Server *server = [Server MR_findFirstInContext:localContext];
//        if (server) {
//            NSMutableDictionary *properties = [server.properties mutableCopy];
//            [properties setObject:property forKey:key];
//            server.properties = properties;
//        } else {
//            server = [Server MR_createEntityInContext:localContext];
//            server.properties = @{key: property};
//        }
//    } completion:^(BOOL contextDidSave, NSError * _Nullable error) {
//        if (completion) {
//            completion(contextDidSave, error);
//        }
//    }];
//}
//
//@end

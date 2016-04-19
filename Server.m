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
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Server" inManagedObjectContext:context]];
    request.fetchLimit = 1;
    
    NSError *error;
    NSArray *servers = [context executeFetchRequest:request error:&error];
    
    if (error) {
        NSLog(@"Error getting server properties from database");
        return nil;
    }
    
    id property = nil;
    if (servers.count == 1) {
        Server *server = [servers objectAtIndex:0];
        if (server) {
            NSDictionary *properties = server.properties;
            property = [properties objectForKey:key];
        }
    }
    
    return property;
}

+(void) setProperty:(id) property forKey:(NSString *)key {
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Server" inManagedObjectContext:context]];
    request.fetchLimit = 1;
    
    NSArray *servers = [context executeFetchRequest:request error:nil];
    if (servers.count != 1) {
        Server *server = [NSEntityDescription insertNewObjectForEntityForName:@"Server" inManagedObjectContext:context];
        server.properties = @{key: property};
    } else {
        Server *server = [servers objectAtIndex:0];
        NSMutableDictionary *properties = [server.properties mutableCopy];
        [properties setObject:property forKey:key];
        server.properties = properties;
    }
    
    NSError *error = nil;
    if (! [context save:&error]) {
        NSLog(@"Error updating server properties: %@", error);
    }
}

@end

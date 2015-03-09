//
//  Event+helper.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 3/2/15.
//  Copyright (c) 2015 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Event+helper.h"
#import "MageServer.h"
#import "HttpManager.h"
#import "User+helper.h"
#import <Server+helper.h>

NSString * const MAGEEventsFetched = @"mil.nga.giat.mage.events.fetched";

static id AFJSONObjectByRemovingKeysWithNullValues(id JSONObject, NSJSONReadingOptions readingOptions) {
    if ([JSONObject isKindOfClass:[NSArray class]]) {
        NSMutableArray *mutableArray = [NSMutableArray arrayWithCapacity:[(NSArray *)JSONObject count]];
        for (id value in (NSArray *)JSONObject) {
            [mutableArray addObject:AFJSONObjectByRemovingKeysWithNullValues(value, readingOptions)];
        }
        
        return (readingOptions & NSJSONReadingMutableContainers) ? mutableArray : [NSArray arrayWithArray:mutableArray];
    } else if ([JSONObject isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *mutableDictionary = [NSMutableDictionary dictionaryWithDictionary:JSONObject];
        for (id <NSCopying> key in [(NSDictionary *)JSONObject allKeys]) {
            id value = [(NSDictionary *)JSONObject objectForKey:key];
            if (!value || [value isEqual:[NSNull null]]) {
                [mutableDictionary removeObjectForKey:key];
            } else if ([value isKindOfClass:[NSArray class]] || [value isKindOfClass:[NSDictionary class]]) {
                [mutableDictionary setObject:AFJSONObjectByRemovingKeysWithNullValues(value, readingOptions) forKey:key];
            }
        }
        
        return (readingOptions & NSJSONReadingMutableContainers) ? mutableDictionary : [NSDictionary dictionaryWithDictionary:mutableDictionary];
    }
    
    return JSONObject;
}


@implementation Event (helper)

+ (Event *) insertEventForJson: (NSDictionary *) json myself:(BOOL) myself inManagedObjectContext:(NSManagedObjectContext *) context {
    Event *event = [Event MR_createEntityInContext:context];
    [event updateEventForJson:json];
    
    return event;
}

+ (Event *) insertEventForJson: (NSDictionary *) json inManagedObjectContext:(NSManagedObjectContext *) context {
    return [Event insertEventForJson:json myself:NO inManagedObjectContext:context];
}

- (void) updateEventForJson: (NSDictionary *) json {
    [self setRemoteId:[json objectForKey:@"id"]];
    [self setName:[json objectForKey:@"name"]];
    [self setEventDescription:[json objectForKey:@"description"]];
    [self setForm:AFJSONObjectByRemovingKeysWithNullValues([json objectForKey:@"form"], NSJSONReadingAllowFragments)];
}

+ (NSOperation *) operationToFetchEvents {
    NSString *url = [NSString stringWithFormat:@"%@/%@", [MageServer baseURL], @"api/events"];
    
    NSLog(@"Pulling events from the server %@", url);
    
    HttpManager *http = [HttpManager singleton];
    
    NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: nil error: nil];
    NSOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id events) {
        
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            User *current = [User fetchCurrentUserInManagedObjectContext:localContext];
            
            NSMutableArray *eventsReturned = [[NSMutableArray alloc] init];
            for (NSDictionary *eventJson in events) {
                Event *event = [Event MR_findFirstByAttribute:@"remoteId" withValue:[eventJson objectForKey:@"id"] inContext:localContext];
                if (event == nil) {
                    event = [Event insertEventForJson:eventJson inManagedObjectContext:localContext];
                } else {
                    [event updateEventForJson:eventJson];
                }
                [event setRecentSortOrder:[NSNumber numberWithLong:[current.recentEventIds indexOfObject:event.remoteId]]];
                [eventsReturned addObject:[eventJson objectForKey:@"id"]];
            }
            
            NSArray *eventsRemoved = [Event MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"NOT (remoteId IN %@)", eventsReturned] inContext:localContext];
            for (Event *e in eventsRemoved) {
                [e MR_deleteEntity];
            }
            
        } completion:^(BOOL contextDidSave, NSError *error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:MAGEEventsFetched object:nil];
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    return operation;
}

+ (void) sendRecentEvent {
    User *u = [User fetchCurrentUserInManagedObjectContext: [NSManagedObjectContext MR_defaultContext]];
    NSString *url = [NSString stringWithFormat:@"%@/api/users/%@/events/%@/recent", [MageServer baseURL], u.remoteId, [Server currentEventId]];
    
    HttpManager *http = [HttpManager singleton];
    
    NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"POST" URLString:url parameters: nil error: nil];
    NSOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id repsonse) {
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
    [http.manager.operationQueue addOperation:operation];
}

+ (Event *) getCurrentEvent {
    return [Event MR_findFirstByAttribute:@"remoteId" withValue:[Server currentEventId]];
}


@end

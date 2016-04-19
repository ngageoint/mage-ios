//
//  Event.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Event.h"
#import "Team.h"
#import "User.h"
#import "Server.h"
#import "StaticLayer.h"

#import "MageServer.h"
#import "HttpManager.h"

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

@implementation Event

+ (Event *) insertEventForJson: (NSDictionary *) json inManagedObjectContext:(NSManagedObjectContext *) context {
    Event *event = [Event MR_createEntityInContext:context];
    [event updateEventForJson:json inManagedObjectContext:context];
    return event;
}

- (void) updateEventForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context {
    [self setRemoteId:[json objectForKey:@"id"]];
    [self setName:[json objectForKey:@"name"]];
    [self setEventDescription:[json objectForKey:@"description"]];
    [self setForm:AFJSONObjectByRemovingKeysWithNullValues([json objectForKey:@"form"], NSJSONReadingAllowFragments)];
    for (NSDictionary *teamJson in [json objectForKey:@"teams"]) {
        NSSet *filteredTeams = [self.teams filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"remoteId == %@", [teamJson objectForKey:@"id"]]];
        if (filteredTeams.count == 1) {
            Team *team = [filteredTeams anyObject];
            [team updateTeamForJson:teamJson inManagedObjectContext:context];
        } else {
            Team *team = [Team MR_findFirstByAttribute:@"remoteId" withValue:[teamJson objectForKey:@"id"] inContext:context];
            if (team) {
                [team updateTeamForJson:teamJson inManagedObjectContext:context];
                [self addTeamsObject:team];
            } else {
                team = [Team insertTeamForJson:teamJson inManagedObjectContext:context];
                [self addTeamsObject:team];
            }
        }
    }
    for (NSDictionary *layerJson in [json objectForKey:@"layers"]) {
        NSString *layerType = [Layer layerTypeFromJson:layerJson];
        if ([layerType isEqualToString:@"Feature"]) {
            [StaticLayer createOrUpdateStaticLayer:layerJson withEventId:self.remoteId inContext:context];
        } else {
            Layer *layer = [Layer MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"remoteId == %@ AND eventId == %@", [layerJson objectForKey:@"remoteId"], self.remoteId] inContext:context];
            if (!layer) {
                layer = [Layer MR_createEntityInContext:context];
            }
            [layer populateObjectFromJson:layerJson withEventId:self.remoteId];
        }
    }
}

- (BOOL) isUserInEvent: (User *) user {
    for (Team *t in user.teams) {
        // doing this because chcking if the team is in the set didn't work
        for(Team* eventTeam in self.teams) {
            if ([eventTeam.remoteId isEqualToString:t.remoteId]) {
                return true;
            }
        }
    }
    NSLog(@"User %@ is not in the event %@", user.name, self.name);
    return false;
}

+ (NSOperation *) operationToFetchEventsWithSuccess: (void (^)()) success failure: (void (^)(NSError *)) failure {
    NSString *url = [NSString stringWithFormat:@"%@/%@", [MageServer baseURL], @"api/events"];
    
    NSLog(@"Pulling events from the server %@", url);
    
    HttpManager *http = [HttpManager singleton];
    
    NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: nil error: nil];
    NSOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id events) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            User *localUser = [User fetchCurrentUserInManagedObjectContext:localContext];
            
            NSMutableArray *eventsReturned = [[NSMutableArray alloc] init];
            for (NSDictionary *eventJson in events) {
                Event *event = [Event MR_findFirstByAttribute:@"remoteId" withValue:[eventJson objectForKey:@"id"] inContext:localContext];
                if (event == nil) {
                    event = [Event insertEventForJson:eventJson inManagedObjectContext:localContext];
                } else {
                    [event updateEventForJson:eventJson inManagedObjectContext:localContext];
                }
                [event setRecentSortOrder:[NSNumber numberWithLong:[localUser.recentEventIds indexOfObject:event.remoteId]]];
                [eventsReturned addObject:[eventJson objectForKey:@"id"]];
            }
            
            [Event MR_deleteAllMatchingPredicate:[NSPredicate predicateWithFormat:@"NOT (remoteId IN %@)", eventsReturned] inContext:localContext];
            
        } completion:^(BOOL contextDidSave, NSError *error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:MAGEEventsFetched object:nil];
            if (error) {
                if (failure) {
                    failure(error);
                }
            } else if (success) {
                success();
            }
        }];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
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

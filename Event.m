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
#import "MageSessionManager.h"

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

+ (NSFetchedResultsController *) caseInsensitiveSortFetchAll:(NSString *)sortTerm ascending:(BOOL)ascending withPredicate:(nullable NSPredicate *)searchTerm groupBy:(nullable NSString *)groupingKeyPath inContext: (NSManagedObjectContext *) context {
    NSFetchRequest *request = [Event MR_requestAllInContext:context];
    if (searchTerm) {
        [request setPredicate:searchTerm];
    }
    [request setIncludesSubentities:NO];
    
    if (sortTerm != nil){
        NSSortDescriptor* sortBy = [NSSortDescriptor sortDescriptorWithKey:sortTerm ascending:ascending selector:@selector(caseInsensitiveCompare:)];
        [request setSortDescriptors:[NSArray arrayWithObject:sortBy]];
    }
    
    NSFetchedResultsController *controller = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                                 managedObjectContext:context
                                                                                   sectionNameKeyPath:groupingKeyPath
                                                                                            cacheName:nil];
    return controller;
}

- (void) updateEventForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context {
    [self setRemoteId:[json objectForKey:@"id"]];
    [self setName:[json objectForKey:@"name"]];
    [self setEventDescription:[json objectForKey:@"description"]];
    [self setAcl:AFJSONObjectByRemovingKeysWithNullValues([json objectForKey:@"acl"], NSJSONReadingAllowFragments)];
    [self setForms:AFJSONObjectByRemovingKeysWithNullValues([json objectForKey:@"forms"], NSJSONReadingAllowFragments)];
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
    for (Team *eventTeam in self.teams) {
        if ([eventTeam.users containsObject:user]) {
            return true;
        }
    }
    
    NSLog(@"User %@ is not in the event %@", user.name, self.name);
    return false;
}

- (NSDictionary *) formForObservation: (Observation *) observation {
    return [observation getPrimaryForm];
}

- (NSDictionary *) formWithId: (long) formId {
    for (NSDictionary *form in self.forms) {
        if ((long)[form objectForKey:@"id"] == formId) {
            return form;
        }
    }
    return nil;
}

- (NSArray *) nonArchivedForms {
    NSMutableArray *nonArchivedForms = [[NSMutableArray alloc] init];
    for (NSDictionary *form in self.forms) {
        if (((NSNumber *)[form objectForKey:@"archived"]).boolValue == NO) {
            [nonArchivedForms addObject:form];
        }
    }
    return nonArchivedForms;
}

+ (NSURLSessionDataTask *) operationToFetchEventsWithSuccess: (void (^)(void)) success failure: (void (^)(NSError *)) failure {
    NSString *url = [NSString stringWithFormat:@"%@/%@", [MageServer baseURL], @"api/events"];
    
    NSLog(@"Pulling events from the server %@", url);
    
    NSURL *URL = [NSURL URLWithString:url];
    MageSessionManager *manager = [MageSessionManager manager];
    NSURLSessionDataTask *task = [manager GET_TASK:URL.absoluteString parameters:nil progress:nil success:^(NSURLSessionTask *task, id events) {
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
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        if (failure) {
            failure(error);
        }
    }];
    
    return task;
}

+ (void) sendRecentEvent {
    User *u = [User fetchCurrentUserInManagedObjectContext: [NSManagedObjectContext MR_defaultContext]];
    NSString *url = [NSString stringWithFormat:@"%@/api/users/%@/events/%@/recent", [MageServer baseURL], u.remoteId, [Server currentEventId]];
    
    NSURL *URL = [NSURL URLWithString:url];
    MageSessionManager *manager = [MageSessionManager manager];
    NSURLSessionDataTask *task = [manager POST_TASK:URL.absoluteString parameters:nil progress:nil success:^(NSURLSessionTask *task, id events) {
        
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
    }];
    
    [manager addTask:task];
}

+ (Event *) getCurrentEventInContext:(NSManagedObjectContext *) context {
    return [Event MR_findFirstByAttribute:@"remoteId" withValue:[Server currentEventId] inContext:context];
}

+ (Event *) getEventById: (id) eventId inContext: (NSManagedObjectContext *) context {
    return [Event MR_findFirstByAttribute:@"remoteId" withValue:eventId inContext:context];
}

@end

//
//  ObservationRoutes.m
//  mage-ios-sdk
//
//  Created by Daniel Barela on 3/17/21.
//  Copyright © 2021 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "ObservationRoutes.h"
#import "NSDate+Iso8601.h"
#import "MAGE-Swift.h"
@import Persistence;

@implementation ObservationRoutes

+ (instancetype) singleton {
    static ObservationRoutes *routes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        routes = [[self alloc] init];
    });
    return routes;
}

- (RouteMethod *) pull: (NSNumber *) eventId {
    RouteMethod *method = [[RouteMethod alloc] init];
    method.method = @"GET";
    method.route = [NSString stringWithFormat:@"%@/api/events/%@/observations", [MageServer baseURL], eventId];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObject:@"lastModified+DESC" forKey:@"sort"];
    __block NSDate *lastObservationDate = [Observation fetchLastObservationDateWithContext:[NSManagedObjectContext MR_defaultContext]];
    if (lastObservationDate != nil) {
        [parameters setObject:[lastObservationDate iso8601String] forKey:@"startDate"];
    }
    method.parameters = parameters;
    return method;
}

- (RouteMethod *) deleteRoute: (NSManagedObject *) observation {
    Observation *strongObservation = (Observation *)observation;
    RouteMethod *method = [[RouteMethod alloc] init];
    method.method = @"POST";
    method.route = [NSString stringWithFormat:@"%@/states", strongObservation.url];
    method.parameters = @{@"name":@"archive"};
    return method;
}

- (RouteMethod *) createId: (NSManagedObject *) observation {
    Observation *strongObservation = (Observation *)observation;
    RouteMethod *method = [[RouteMethod alloc] init];
    method.method = @"POST";
    method.route = [NSString stringWithFormat:@"%@/api/events/%@/observations/id", [MageServer baseURL], strongObservation.eventId];
    return method;
}

- (RouteMethod *) pushFavorite: (NSManagedObject *) favorite {
    ObservationFavorite *strongFavorite = (ObservationFavorite *)favorite;
    RouteMethod *method = [[RouteMethod alloc] init];
    method.method = strongFavorite.favorite ? @"PUT" : @"DELETE";
    method.route = [NSString stringWithFormat:@"%@/api/events/%@/observations/%@/favorite", [MageServer baseURL], strongFavorite.observation.eventId, strongFavorite.observation.remoteId];
    return method;
}

- (RouteMethod *) pushImportant: (NSManagedObject *) important {
    ObservationImportant *strongImportant = (ObservationImportant *)important;
    RouteMethod *method = [[RouteMethod alloc] init];
    method.method = strongImportant.important ? @"PUT" : @"DELETE";
    method.route = [NSString stringWithFormat:@"%@/api/events/%@/observations/%@/important", [MageServer baseURL], strongImportant.observation.eventId, strongImportant.observation.remoteId];
    method.parameters = @{@"description":strongImportant.reason};
    return method;
}

@end

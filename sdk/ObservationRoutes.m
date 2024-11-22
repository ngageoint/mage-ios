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

@implementation ObservationRoutes

+ (instancetype) singleton {
    static ObservationRoutes *routes = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        routes = [[self alloc] init];
    });
    return routes;
}

- (RouteMethod *) pull: (NSNumber *) eventId context: (NSManagedObjectContext *) context {
    RouteMethod *method = [[RouteMethod alloc] init];
    method.method = @"GET";
    method.route = [NSString stringWithFormat:@"%@/api/events/%@/observations", [MageServer baseURL], eventId];
    NSMutableDictionary *parameters = [NSMutableDictionary dictionaryWithObject:@"lastModified+DESC" forKey:@"sort"];
    __block NSDate *lastObservationDate = [Observation fetchLastObservationDateWithContext:context];
    if (lastObservationDate != nil) {
        [parameters setObject:[lastObservationDate iso8601String] forKey:@"startDate"];
    }
    method.parameters = parameters;
    return method;
}

- (RouteMethod *) deleteRoute: (Observation *) observation {
    RouteMethod *method = [[RouteMethod alloc] init];
    method.method = @"POST";
    method.route = [NSString stringWithFormat:@"%@/states", observation.url];
    method.parameters = @{@"name":@"archive"};
    return method;
}

- (RouteMethod *) createId: (Observation *) observation {
    RouteMethod *method = [[RouteMethod alloc] init];
    method.method = @"POST";
    method.route = [NSString stringWithFormat:@"%@/api/events/%@/observations/id", [MageServer baseURL], observation.eventId];
    return method;
}

- (RouteMethod *) pushFavorite: (ObservationFavorite *) favorite {
    RouteMethod *method = [[RouteMethod alloc] init];
    method.method = favorite.favorite ? @"PUT" : @"DELETE";
    method.route = [NSString stringWithFormat:@"%@/api/events/%@/observations/%@/favorite", [MageServer baseURL], favorite.observation.eventId, favorite.observation.remoteId];
    return method;
}

- (RouteMethod *) pushImportant: (ObservationImportant *) important {
    RouteMethod *method = [[RouteMethod alloc] init];
    method.method = important.important ? @"PUT" : @"DELETE";
    method.route = [NSString stringWithFormat:@"%@/api/events/%@/observations/%@/important", [MageServer baseURL], important.observation.eventId, important.observation.remoteId];
    method.parameters = @{@"description":important.reason};
    return method;
}

@end

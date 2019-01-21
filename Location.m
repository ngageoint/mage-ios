//
//  Location.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

@import DateTools;

#import "Location.h"
#import "User.h"
#import "Server.h"
#import "MageSessionManager.h"
#import "MageServer.h"
#import "NSDate+Iso8601.h"
#import "SFGeometryUtils.h"

@implementation Location

@synthesize geometry;

- (CLLocation *) location {
    SFPoint *centroid = [SFGeometryUtils centroidOfGeometry:self.geometry];
    return [[CLLocation alloc] initWithLatitude:[centroid.y doubleValue] longitude:[centroid.x doubleValue]];
}

- (NSString *) sectionName {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    
    return [dateFormatter stringFromDate:self.timestamp];
}

- (void) populateLocationFromJson:(NSArray *) locations {
    if (locations.count) {
        for (NSDictionary* jsonLocation in locations) {
            [self setRemoteId:[jsonLocation objectForKey:@"id"]];
            [self setType:[jsonLocation objectForKey:@"type"]];
            [self setEventId:[jsonLocation objectForKey:@"eventId"]];
            NSDate *date = [NSDate dateFromIso8601String:[jsonLocation valueForKeyPath:@"properties.timestamp"]];
            [self setTimestamp:date];
            [self setProperties:[jsonLocation valueForKeyPath:@"properties"]];
            
            NSArray *coordinates = [jsonLocation valueForKeyPath:@"geometry.coordinates"];
            CLLocation *location = [[CLLocation alloc]
                                    initWithCoordinate:CLLocationCoordinate2DMake([[coordinates objectAtIndex: 1] floatValue], [[coordinates objectAtIndex: 0] floatValue])
                                    altitude:[[jsonLocation valueForKeyPath:@"properties.altitude"] floatValue]
                                    horizontalAccuracy:[[jsonLocation valueForKeyPath:@"properties.altitude"] floatValue]
                                    verticalAccuracy:[[jsonLocation valueForKeyPath:@"properties.accuracy"] floatValue]
                                    course:[[jsonLocation valueForKeyPath:@"properties.bearing"] floatValue]
                                    speed:[[jsonLocation valueForKeyPath:@"properties.speed"] floatValue]
                                    timestamp:date];
            
            [self setGeometry:[[SFPoint alloc] initWithXValue:location.coordinate.longitude andYValue:location.coordinate.latitude]];
        }
    } else {
        // delete user record from core data
    }
}


+ (NSURLSessionDataTask *) operationToPullLocationsWithSuccess: (void (^)(void)) success failure: (void (^)(NSError *)) failure {
    NSString *url = [NSString stringWithFormat:@"%@/api/events/%@/locations/users", [MageServer baseURL], [Server currentEventId]];
    NSLog(@"Trying to fetch locations from server %@", url);
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    __block NSDate *lastLocationDate = [self fetchLastLocationDate];
    if (lastLocationDate != nil) {
        [parameters setObject:[lastLocationDate iso8601String] forKey:@"startDate"];
    }
    
    MageSessionManager *manager = [MageSessionManager manager];
    
    NSURLSessionDataTask *task = [manager GET_TASK:url parameters:parameters progress:nil success:^(NSURLSessionTask *task, id allUserLocations) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            NSLog(@"Fetched %lu locations from the server, saving to location storage", (unsigned long)[allUserLocations count]);
            User *currentUser = [User fetchCurrentUserInManagedObjectContext:localContext];
            
            // Get the user ids to query
            NSMutableArray *userIds = [[NSMutableArray alloc] init];
            for (NSDictionary *user in allUserLocations) {
                [userIds addObject:[user objectForKey:@"id"]];
            }
            
            NSArray *usersMatchingIDs = [User MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId IN %@)", userIds] inContext:localContext];
            NSMutableDictionary *userIdMap = [[NSMutableDictionary alloc] init];
            for (User *user in usersMatchingIDs) {
                [userIdMap setObject:user forKey:user.remoteId];
            }
            
            BOOL newUserFound = NO;
            for (NSDictionary *userJson in allUserLocations) {
                // pull from query map
                NSString *userId = [userJson objectForKey:@"id"];
                NSArray *locations = [userJson objectForKey:@"locations"];
                User *user = [userIdMap objectForKey:userId];
                if (user == nil && [locations count] != 0) {
                    NSLog(@"Could not find user for id");
                    newUserFound = YES;
                    NSDictionary *userDictionary = @{
                                                     @"id": userId,
                                                     @"username": userId,
                                                     @"displayName": @"unknown"
                                                     };
                    
                    user = [User insertUserForJson:userDictionary inManagedObjectContext:localContext];
                };
                if ([currentUser.remoteId isEqualToString:user.remoteId]) continue;
                
                Location *location = user.location;
                if (location == nil) {
                    // not in core data yet need to create a new managed object
                    location = [Location MR_createEntityInContext:localContext];
                    NSArray *locations = [userJson objectForKey:@"locations"];
                    [location populateLocationFromJson:locations];
                    user.location = location;
                } else {
                    // already exists in core data, lets update the object we have
                    [location populateLocationFromJson:locations];
                }
            }
            
            if (newUserFound) {
                // For now if we find at least one new user let just go grab the users again
                [User operationToFetchUsersWithSuccess:^{
                } failure:^(NSError * error) {
                }];
            }
        } completion:^(BOOL contextDidSave, NSError *error) {
            if (error) {
                if (failure) {
                    failure(error);
                }
            } else if (success){
                success();
            }
        }];
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        if (failure) {
            failure(error);
        }
    }];
    
    return task;
}

+ (NSDate *) fetchLastLocationDate {
    NSDate *date = nil;

    Location *location = [Location MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"eventId == %@", [Server currentEventId]] sortedBy:@"timestamp" ascending:NO];
    if (location) {
        date = location.timestamp;
    }
    
    return date;
}

- (NSString *)sectionIdentifier {
    return [self timestamp].timeAgoSinceNow;
}
@end

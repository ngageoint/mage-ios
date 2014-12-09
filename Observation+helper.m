//
//  Observation+Observation_helper.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 5/8/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Observation+helper.h"
#import "HttpManager.h"
#import "MageEnums.h"
#import "GeoPoint.h"
#import "Attachment+helper.h"
#import <NSDate+DateTools.h>
#import "NSDate+Iso8601.h"
#import "MageServer.h"
#import "Server+helper.h"
#import "NSManagedObjectContext+MAGE.h"
#import <Server+helper.h>
#import <User+helper.h>


@implementation Observation (helper)

NSMutableArray *_transientAttachments;

NSDictionary *_fieldNameToField;

- (NSMutableArray *)transientAttachments {
    if (_transientAttachments != nil) {
        return _transientAttachments;
    }
    _transientAttachments = [NSMutableArray array];
    return _transientAttachments;
}

- (NSDictionary *)fieldNameToField {
    if (_fieldNameToField != nil) {
        return _fieldNameToField;
    }
    NSDictionary *form = [Server observationForm];
    
    NSMutableDictionary *fieldNameToFieldMap = [[NSMutableDictionary alloc] init];
    // run through the form and map the row indexes to fields
    for (id field in [form objectForKey:@"fields"]) {
        [fieldNameToFieldMap setObject:field forKey:[field objectForKey:@"name"]];
    }
    _fieldNameToField = fieldNameToFieldMap;
    
    return _fieldNameToField;
}

- (NSDictionary *) createJsonToSubmit {
    
    NSDateFormatter *dateFormat = [NSDateFormatter new];
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    dateFormat.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    // Always use this locale when parsing fixed format date strings
    NSLocale* posix = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormat.locale = posix;

    
    NSMutableDictionary *observationJson = [[NSMutableDictionary alloc] init];
    
    if (self.remoteId != nil) {
        [observationJson setObject:self.remoteId forKey:@"id"];
    }
    if (self.userId != nil) {
        [observationJson setObject:self.userId forKey:@"userId"];
    }
    if (self.deviceId != nil) {
        [observationJson setObject:self.deviceId forKey:@"deviceId"];
    }
    if (self.url != nil) {
        [observationJson setObject:self.url forKey:@"url"];
    }
    [observationJson setObject:@"Feature" forKey:@"type"];
    
    NSString *stringState = [[NSString alloc] StringFromStateInt:[self.state intValue]];
    
    [observationJson setObject:@{
                                 @"name": stringState
                                 } forKey:@"state"];
    
    GeoPoint *point = (GeoPoint *)self.geometry;
    [observationJson setObject:@{
                                 @"type": @"Point",
                                 @"coordinates": @[[NSNumber numberWithDouble:point.location.coordinate.longitude], [NSNumber numberWithDouble:point.location.coordinate.latitude]]
                                 } forKey:@"geometry"];
    [observationJson setObject: [dateFormat stringFromDate:self.timestamp] forKey:@"timestamp"];
    
    NSMutableDictionary *jsonProperties = [[NSMutableDictionary alloc] initWithDictionary:self.properties];
        
    for (id key in self.properties) {
        id value = [self.properties objectForKey:key];
        id field = [[self fieldNameToField] objectForKey:key];
        if ([[field objectForKey:@"type"] isEqualToString:@"geometry"]) {
            GeoPoint *point = value;
            [jsonProperties setObject:@{@"x": [NSNumber numberWithDouble:point.location.coordinate.latitude],
              @"y": [NSNumber numberWithDouble: point.location.coordinate.longitude]
                                        } forKey: key];
            
        }
    }

    [observationJson setObject:jsonProperties forKey:@"properties"];
    return observationJson;
}

- (void) addTransientAttachment: (Attachment *) attachment {
    [self.transientAttachments addObject:attachment];
}

- (void) initializeNewObservationWithLocation:(GeoPoint *)location {
    NSDateFormatter *dateFormat = [NSDateFormatter new];
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    dateFormat.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    // Always use this locale when parsing fixed format date strings
    NSLocale* posix = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormat.locale = posix;
    [self setTimestamp:[NSDate date]];
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    
    [properties setObject:[dateFormat stringFromDate:[self timestamp]] forKey:@"timestamp"];
    
    [self setProperties:properties];
    [self setUser:[User fetchCurrentUser]];
    [self setGeometry:location];
    [self setDirty:[NSNumber numberWithBool:NO]];
    [self setState:[NSNumber numberWithInt:(int)[@"active" StateEnumFromString]]];
}

- (id) populateObjectFromJson: (NSDictionary *) json {
    [self setRemoteId:[json objectForKey:@"id"]];
    [self setUserId:[json objectForKey:@"userId"]];
    [self setDeviceId:[json objectForKey:@"deviceId"]];
    [self setDirty:[NSNumber numberWithBool:NO]];
    NSDictionary *properties = [json objectForKey: @"properties"];
    
    [self setProperties:[self generatePropertiesFromRaw:properties]];
    
    NSDateFormatter *dateFormat = [NSDateFormatter new];
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    dateFormat.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    // Always use this locale when parsing fixed format date strings
    NSLocale* posix = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormat.locale = posix;
    NSDate *date = [dateFormat dateFromString:[json objectForKey:@"lastModified"]];
    [self setLastModified:date];
    
    NSDate *timestamp = [dateFormat dateFromString:[self.properties objectForKey:@"timestamp"]];
    [self setTimestamp:timestamp];
    
    [self setUrl:[json objectForKey:@"url"]];
    NSDictionary *jsonState = [json objectForKey: @"state"];
    NSString *stateName = [jsonState objectForKey: @"name"];
    State enumValue = [stateName StateEnumFromString];
    [self setState:[NSNumber numberWithInt:(int)enumValue]];
    
    NSArray *coordinates = [json valueForKeyPath:@"geometry.coordinates"];
    CLLocation *location = [[CLLocation alloc] initWithLatitude:[[coordinates objectAtIndex:1] floatValue] longitude:[[coordinates objectAtIndex:0] floatValue]];
    
    [self setGeometry:[[GeoPoint alloc] initWithLocation:location]];
    return self;
}

- (NSDictionary *) generatePropertiesFromRaw: (NSDictionary *) propertyJson {
    
    NSMutableDictionary *parsedProperties = [[NSMutableDictionary alloc] initWithDictionary:propertyJson];
    
    for (id key in propertyJson) {
        id value = [propertyJson objectForKey:key];
        id field = [[self fieldNameToField] objectForKey:key];
        if ([[field objectForKey:@"type"] isEqualToString:@"geometry"]) {
            CLLocation *location = [[CLLocation alloc] initWithLatitude:[[value objectForKey:@"x"] floatValue] longitude:[[value objectForKey:@"y"] floatValue]];
            
            [parsedProperties setObject:[[GeoPoint alloc] initWithLocation:location] forKey:key];
        }
    }
    
    return parsedProperties;
}

- (CLLocation *) location {
    GeoPoint *point = (GeoPoint *) self.geometry;
    return point.location;
}

- (NSString *) sectionName {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyy-MM-dd";
    
    return [dateFormatter stringFromDate:self.timestamp];
}

+ (id) observationForJson: (NSDictionary *) json {
    Observation *observation = [[Observation alloc] initWithEntity:[NSEntityDescription entityForName:@"Observation" inManagedObjectContext:[NSManagedObjectContext defaultManagedObjectContext]] insertIntoManagedObjectContext:nil];
    [observation populateObjectFromJson:json];
    
    return observation;
}

+ (NSOperation *) operationToPushObservation:(Observation *) observation success:(void (^)()) success failure: (void (^)()) failure {
    NSNumber *layerId = [Server observationLayerId];
    NSString *url = [NSString stringWithFormat:@"%@/FeatureServer/%@/features", [MageServer baseURL], layerId];
    NSLog(@"Trying to push observation to server %@", url);
    
    HttpManager *http = [HttpManager singleton];
    NSMutableArray *parameters = [[NSMutableArray alloc] init];
    NSObject *json = [observation createJsonToSubmit];
    [parameters addObject:json];
    
    NSString *requestMethod = @"POST";
    if (observation.remoteId != nil) {
        requestMethod = @"PUT";
        url = observation.url;
    }
    
    NSMutableURLRequest *request = [http.manager.requestSerializer requestWithMethod:requestMethod URLString:url parameters:json error: nil];
    NSOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id response) {
        success(response);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        failure();
    }];
    
    return operation;
}

+ (NSOperation *) operationToPullObservations:(void (^) (BOOL success)) complete {

    NSNumber *layerId = [Server observationLayerId];
    NSString *url = [NSString stringWithFormat:@"%@/FeatureServer/%@/features", [MageServer baseURL], layerId];
    NSLog(@"Fetching from layer %@", layerId);
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    __block NSDate *lastObservationDate = [Observation fetchLastObservationDate];
    if (lastObservationDate != nil) {
        [parameters setObject:[lastObservationDate iso8601String] forKey:@"startDate"];
    }
    
    HttpManager *http = [HttpManager singleton];
    
    NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: parameters error: nil];
    NSOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Observation request complete");
        NSArray *features = [responseObject objectForKey:@"features"];
        NSManagedObjectContext *context = [NSManagedObjectContext defaultManagedObjectContext];
        
        for (id feature in features) {
            Observation *o = [Observation observationForJson:feature];
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
            [fetchRequest setEntity:[NSEntityDescription entityForName:@"User" inManagedObjectContext:context]];
            [fetchRequest setPredicate: [NSPredicate predicateWithFormat:@"(remoteId = %@)", o.userId]];
            NSError *error;
            NSArray *usersMatchingIDs = [context executeFetchRequest:fetchRequest error:&error];
            
            NSSet *existingObservations = [context fetchObjectsForEntityName:@"Observation" withPredicate:@"(remoteId == %@)", o.remoteId];
            Observation *dbObs = [existingObservations anyObject];
            
            //NSLog(@"there are %d observations", existingObservations.count);
            int archive = [@"archive" IntFromStateEnum];
            // if the Observation is archived and used to exist on this device, delete it
            if ([o.state intValue] == archive && dbObs != nil) {
                [context deleteObject:dbObs];
                NSLog(@"Deleting observation with id: %@", o.remoteId);
            }
            // else if the observation is not archived and doesn't exist, insert it
            else if ([o.state intValue] != archive && dbObs == nil) {
                [context insertObject:o];
                o.user = [usersMatchingIDs objectAtIndex:0];
                NSArray *attachments = [feature objectForKey:@"attachments"];
                for (id attachment in attachments) {
                    Attachment * a = [Attachment attachmentForJson:attachment];
                    [context insertObject:a];
                    [o addAttachmentsObject:a];
                }
                NSLog(@"Saving new observation with id: %@", o.remoteId);
            }
            // else if the observation is not archived, and not dirty and exists, update it
            else if ([o.state intValue] != archive && ![dbObs.dirty boolValue]) {
                [dbObs populateObjectFromJson:feature];
                dbObs.user = [usersMatchingIDs objectAtIndex:0];
                NSArray *attachments = [feature objectForKey:@"attachments"];
                
                BOOL found = NO;
                for (id a in attachments) {
                    NSString *remoteId = [a objectForKey:@"id"];
                    found = NO;
                    for (Attachment *dbAttachment in dbObs.attachments) {
                        if (remoteId != nil && [remoteId isEqualToString:dbAttachment.remoteId]) {
                            dbAttachment.contentType = [a objectForKey:@"contentType"];
                            dbAttachment.name = [a objectForKey:@"name"];
                            dbAttachment.remotePath = [a objectForKey:@"remotePath"];
                            dbAttachment.size = [a objectForKey:@"size"];
                            dbAttachment.url = [a objectForKey:@"url"];
                            dbAttachment.observation = dbObs;
                            found = YES;
                            break;
                        }
                    }
                    if (!found) {
                        Attachment * newAttachment = [Attachment attachmentForJson:a inContext:context insertIntoContext:context];
                        newAttachment.observation = dbObs;
                        [dbObs addAttachmentsObject:newAttachment];
                    }
                }

                NSLog(@"Updating object with id: %@", o.remoteId);
            } else {
                NSLog(@"Observation with id: %@ is dirty", o.remoteId);
            }
        }
        
        NSError *error = nil;
        if (! [context save:&error]) {
            NSLog(@"Error inserting Observation: %@", error);
        }
                
        complete(YES);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        complete(NO);
    }];
    
    return operation;
}

+ (NSDate *) fetchLastObservationDate {
    NSManagedObjectContext *context = [NSManagedObjectContext defaultManagedObjectContext];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Observation" inManagedObjectContext:context]];
    request.sortDescriptors = [NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"lastModified" ascending:NO]];
    request.fetchLimit = 1;
    
    NSError *error;
    NSArray *observations = [context executeFetchRequest:request error:&error];
    
    if (error) {
        NSLog(@"Error getting last location from database");
        return nil;
    }
    
    if (observations.count != 1) {
        return nil;
    }
    
    NSDate *date = nil;
    Observation *observation = [observations objectAtIndex:0];
    if (observation) {
        date = observation.timestamp;
    }
    
    return date;
}

@end

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
#import "User+helper.h"
#import "Event+helper.h"

@implementation Observation (helper)

NSMutableArray *_transientAttachments;

NSDictionary *_fieldNameToField;
NSNumber *_currentEventId;


+ (Observation *) observationWithLocation:(GeoPoint *) location inManagedObjectContext:(NSManagedObjectContext *) mangedObjectContext {
    Observation *observation = [Observation MR_createEntityInContext:mangedObjectContext];
    
    NSDateFormatter *dateFormat = [NSDateFormatter new];
    [dateFormat setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    dateFormat.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
    // Always use this locale when parsing fixed format date strings
    NSLocale* posix = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    dateFormat.locale = posix;
    [observation setTimestamp:[NSDate date]];
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];
    
    [properties setObject:[dateFormat stringFromDate:[observation timestamp]] forKey:@"timestamp"];
    
    [observation setProperties:properties];
    [observation setUser:[User fetchCurrentUserInManagedObjectContext:mangedObjectContext]];
    [observation setGeometry:location];
    [observation setDirty:[NSNumber numberWithBool:NO]];
    [observation setState:[NSNumber numberWithInt:(int)[@"active" StateEnumFromString]]];
    [observation setEventId:[Server currentEventId]];
    return observation;
}

+ (NSString *) observationIdFromJson:(NSDictionary *) json {
    return [json objectForKey:@"id"];
}

+ (State) observationStateFromJson:(NSDictionary *) json {
    NSDictionary *stateJson = [json objectForKey: @"state"];
    NSString *stateName = [stateJson objectForKey: @"name"];
    return [stateName StateEnumFromString];
}

- (NSMutableArray *)transientAttachments {
    if (_transientAttachments != nil) {
        return _transientAttachments;
    }
    _transientAttachments = [NSMutableArray array];
    return _transientAttachments;
}

- (NSDictionary *)fieldNameToField {
    if (_fieldNameToField != nil && [_currentEventId isEqualToNumber:[Server currentEventId]]) {
        return _fieldNameToField;
    }
    _currentEventId = [Server currentEventId];
    Event *currentEvent = [Event MR_findFirstByAttribute:@"remoteId" withValue:_currentEventId];
    NSDictionary *form = currentEvent.form;
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

- (id) populateObjectFromJson: (NSDictionary *) json {
    [self setRemoteId:[Observation observationIdFromJson:json]];
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

    State state = [Observation  observationStateFromJson:json];
    [self setState:[NSNumber numberWithInt:(int) state]];
    
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

+ (NSOperation *) operationToPushObservation:(Observation *) observation success:(void (^)()) success failure: (void (^)()) failure {
    NSNumber *eventId = [Server currentEventId];
    NSString *url = [NSString stringWithFormat:@"%@/api/events/%@/observations", [MageServer baseURL], eventId];
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

    __block NSNumber *eventId = [Server currentEventId];
    NSString *url = [NSString stringWithFormat:@"%@/api/events/%@/observations", [MageServer baseURL], eventId];
    NSLog(@"Fetching observations from event %@", eventId);
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    __block NSDate *lastObservationDate = [Observation fetchLastObservationDate];
    if (lastObservationDate != nil) {
        [parameters setObject:[lastObservationDate iso8601String] forKey:@"startDate"];
    }
    
    HttpManager *http = [HttpManager singleton];
    
    NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: parameters error: nil];
    NSOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id features) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            NSLog(@"Observation request complete");
            
            for (id feature in features) {
                NSString *remoteId = [Observation observationIdFromJson:feature];
                State state = [Observation observationStateFromJson:feature];
                
                Observation *existingObservation = [Observation MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId == %@)", remoteId] inContext:localContext];
                // if the Observation is archived, delete it
                if (state == Archive && existingObservation) {
                    NSLog(@"Deleting archived observation with id: %@", remoteId);
                    [existingObservation MR_deleteEntity];
                } else if (state != Archive && !existingObservation) {
                    // if the observation doesn't exist, insert it
                    Observation *observation = [Observation MR_createEntityInContext:localContext];
                    [observation populateObjectFromJson:feature];
                    observation.user = [User MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId = %@)", observation.userId] inContext:localContext];
                    for (id attachmentJson in [feature objectForKey:@"attachments"]) {
                        Attachment *attachment = [Attachment attachmentForJson:attachmentJson inContext:localContext];
                        [observation addAttachmentsObject:attachment];
                    }
                    [observation setEventId:eventId];
                    NSLog(@"Saving new observation with id: %@", observation.remoteId);
                } else if (state != Archive && ![existingObservation.dirty boolValue]) {
                    // if the observation is not dirty, update it
                    [existingObservation populateObjectFromJson:feature];
                    existingObservation.user = [User MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId = %@)", existingObservation.userId] inContext:localContext];

                    BOOL found = NO;
                    for (id attachmentJson in [feature objectForKey:@"attachments"]) {
                        NSString *remoteId = [attachmentJson objectForKey:@"id"];
                        found = NO;
                        for (Attachment *attachment in existingObservation.attachments) {
                            if (remoteId != nil && [remoteId isEqualToString:attachment.remoteId]) {
                                attachment.contentType = [attachmentJson objectForKey:@"contentType"];
                                attachment.name = [attachmentJson objectForKey:@"name"];
                                attachment.remotePath = [attachmentJson objectForKey:@"remotePath"];
                                attachment.size = [attachmentJson objectForKey:@"size"];
                                attachment.url = [attachmentJson objectForKey:@"url"];
                                attachment.observation = existingObservation;
                                found = YES;
                                break;
                            }
                        }
                        if (!found) {
                            Attachment *newAttachment = [Attachment attachmentForJson:attachmentJson inContext:localContext];
                            [existingObservation addAttachmentsObject:newAttachment];
                        }
                    }
                    [existingObservation setEventId:eventId];
                    NSLog(@"Updating object with id: %@", existingObservation.remoteId);
                } else {
                    NSLog(@"Observation with id: %@ is dirty", remoteId);
                }
            }
        } completion:^(BOOL success, NSError *error) {
            complete(success);
        }];

    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        complete(NO);
    }];
    
    return operation;
}

+ (NSDate *) fetchLastObservationDate {
    NSDate *date = nil;
    Observation *observation = [Observation MR_findFirstOrderedByAttribute:@"lastModified" ascending:NO];
    if (observation) {
        date = observation.lastModified;
    }
    
    return date;
}

@end

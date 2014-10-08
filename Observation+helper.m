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

@interface Observation ()

@end

@implementation Observation (helper)

NSDictionary *_fieldNameToField;

- (NSDictionary *)fieldNameToField {
    if (_fieldNameToField != nil) {
        return _fieldNameToField;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *form = [defaults objectForKey:@"form"];
    
    NSMutableDictionary *fieldNameToFieldMap = [[NSMutableDictionary alloc] init];
    // run through the form and map the row indexes to fields
    for (id field in [form objectForKey:@"fields"]) {
        [fieldNameToFieldMap setObject:field forKey:[field objectForKey:@"name"]];
    }
    _fieldNameToField = fieldNameToFieldMap;
    
    return _fieldNameToField;
}

- (id) populateObjectFromJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context {
    [self setRemoteId:[json objectForKey:@"id"]];
    [self setUserId:[json objectForKey:@"userId"]];
    [self setDeviceId:[json objectForKey:@"deviceId"]];
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

+ (id) observationForJson: (NSDictionary *) json inManagedObjectContext: (NSManagedObjectContext *) context {
    Observation *observation = [[Observation alloc] initWithEntity:[NSEntityDescription entityForName:@"Observation" inManagedObjectContext:context] insertIntoManagedObjectContext:nil];
    [observation populateObjectFromJson:json inManagedObjectContext: context];
    
    return observation;
}

+ (NSOperation *) operationToPullObservationsWithManagedObjectContext: (NSManagedObjectContext *) context complete:(void (^) (BOOL success)) complete {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSURL *serverUrl = [defaults URLForKey: @"serverUrl"];
    NSString *layerId = [defaults stringForKey:@"layerId"];
    NSString *url = [NSString stringWithFormat:@"%@/FeatureServer/%@/features", serverUrl, layerId];
    NSLog(@"Fetching from layer %@", layerId);
    
    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    __block NSDate *lastObservationDate = [defaults objectForKey:@"lastObservationDate"];
    if (lastObservationDate != nil) {
        [parameters setObject:lastObservationDate forKey:@"startDate"];
    }
    
    HttpManager *http = [HttpManager singleton];
    
    NSURLRequest *request = [http.manager.requestSerializer requestWithMethod:@"GET" URLString:url parameters: parameters error: nil];
    NSOperation *operation = [http.manager HTTPRequestOperationWithRequest:request success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSLog(@"Observation request complete");
        NSArray *features = [responseObject objectForKey:@"features"];
        
        for (id feature in features) {
            Observation *o = [Observation observationForJson:feature inManagedObjectContext:context];
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
                    Attachment * a = [Attachment attachmentForJson:attachment inManagedObjectContext:context];
                    [context insertObject:a];
                    [o addAttachmentsObject:a];
                }
                NSLog(@"Saving new observation with id: %@", o.remoteId);
            }
            // else if the observation is not archived, and not dirty and exists, update it
            else if ([o.state intValue] != archive && [o.dirty boolValue]) {
                [dbObs populateObjectFromJson:feature inManagedObjectContext:context];
                dbObs.user = [usersMatchingIDs objectAtIndex:0];
                NSArray *attachments = [feature objectForKey:@"attachments"];
                // stupid but for now just do this
                [dbObs setAttachments:nil];
                for (id attachment in attachments) {
                    Attachment * a = [Attachment attachmentForJson:attachment inManagedObjectContext:context];
                    [context insertObject:a];
                    [dbObs addAttachmentsObject:a];
                }
                NSLog(@"Updating object with id: %@", o.remoteId);
            }
            
            if ([o.timestamp isLaterThan:lastObservationDate]) {
                lastObservationDate = o.timestamp;
            }
        }
        
        NSError *error = nil;
        if (! [context save:&error]) {
            NSLog(@"Error inserting Observation: %@", error);
        }
        
        [defaults setObject:lastObservationDate forKey:@"lastObservationDate"];
        [defaults synchronize];
        
        complete(YES);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        complete(NO);
    }];
    
    return operation;
}

@end

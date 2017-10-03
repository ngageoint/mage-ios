//
//  Observation.m
//  mage-ios-sdk
//
//  Created by William Newman on 4/13/16.
//  Copyright © 2016 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Observation.h"
#import "ObservationImportant.h"
#import "ObservationFavorite.h"
#import "Attachment.h"
#import "User.h"
#import "Role.h"
#import "Server.h"
#import "Event.h"
#import "MageSessionManager.h"
#import "MageEnums.h"
#import "NSDate+Iso8601.h"
#import "MageServer.h"
#import "GeometryDeserializer.h"
#import "WKBGeometry.h"
#import "GeometryUtility.h"
#import "GeometrySerializer.h"
#import "GeometryUtility.h"
#import "WKBPolygon.h"
#import "WKBLineString.h"
#import "WKBGeometryUtils.h"
#import "NotificationRequester.h"

NSString * const kObservationErrorStatusCode = @"errorStatusCode";
NSString * const kObservationErrorDescription = @"errorDescription";
NSString * const kObservationErrorMessage = @"errorMessage";

@implementation Observation

NSMutableArray *_transientAttachments;

NSDictionary *_fieldNameToField;
NSNumber *_currentEventId;

+ (Observation *) observationWithGeometry:(WKBGeometry *) geometry inManagedObjectContext:(NSManagedObjectContext *) mangedObjectContext {
    Observation *observation = [Observation MR_createEntityInContext:mangedObjectContext];

    [observation setTimestamp:[NSDate date]];
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init];

    [properties setObject:[observation.timestamp iso8601String] forKey:@"timestamp"];
    [properties setObject:[[NSMutableArray alloc] init] forKey:@"forms"];

    [observation setProperties:properties];
    [observation setUser:[User fetchCurrentUserInManagedObjectContext:mangedObjectContext]];
    [observation setGeometry:geometry];
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

- (Event *) getEvent {
    return [Event getEventById:self.eventId inContext:self.managedObjectContext];
}

- (NSDictionary *) getPrimaryForm {
    Event *event = [self getEvent];
    NSArray *forms = event.forms;
    if (forms != nil && [forms count] > 0) {
        NSArray *observationForms = [self.properties objectForKey:@"forms"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF.id = %@", [[observationForms objectAtIndex:0] objectForKey:@"formId"]];
        NSArray *filteredArray = [forms filteredArrayUsingPredicate:predicate];
        
        return [filteredArray firstObject];
    }
    return nil;
}

- (NSString *) getPrimaryField {
    NSDictionary *form = [self getPrimaryForm];
    if (form != nil) {
        return [form objectForKey:@"primaryField"];
    }
    return nil;
}

- (NSString *) primaryFieldText {
    NSString *primaryField = [self getPrimaryField];
    NSArray *observationForms = [self.properties objectForKey:@"forms"];

    if (primaryField != nil && [observationForms count] > 0) {
        return [[observationForms objectAtIndex:0] objectForKey:primaryField];
    }
    return nil;
}

- (NSString *) getSecondaryField {
    NSDictionary *form = [self getPrimaryForm];
    if (form != nil) {
        return [form objectForKey:@"secondaryField"];
    }
    return nil;
}

- (NSString *) secondaryFieldText {
    
    NSString *secondaryField = [self getSecondaryField];
    NSArray *observationForms = [self.properties objectForKey:@"forms"];

    if (secondaryField != nil && [observationForms count] > 0) {
        return [[observationForms objectAtIndex:0] objectForKey:secondaryField];
    }
    return nil;
}

- (NSMutableArray *)transientAttachments {
    if (_transientAttachments != nil) {
        return _transientAttachments;
    }
    _transientAttachments = [NSMutableArray array];
    return _transientAttachments;
}

- (NSDictionary *)fieldNameToFieldForEvent:(Event *) event andFormId: (id) formId {
    if (_fieldNameToField != nil && [_currentEventId isEqualToNumber:event.remoteId]) {
        return [_fieldNameToField objectForKey:[NSString stringWithFormat:@"%@",formId]];
    }

    _currentEventId = event.remoteId;
    NSArray *forms = event.forms;
    
    NSMutableDictionary *formFieldMap = [[NSMutableDictionary alloc] init];
    
    for (NSDictionary *form in forms) {
        NSMutableDictionary *fieldNameToFieldMap = [[NSMutableDictionary alloc] init];
        // run through the form and map the row indexes to fields
        for (id field in [form objectForKey:@"fields"]) {
            [fieldNameToFieldMap setObject:field forKey:[field objectForKey:@"name"]];
        }
        [formFieldMap setObject:fieldNameToFieldMap forKey:[form objectForKey:@"id"]];
    }
    
    _fieldNameToField = formFieldMap;

    return _fieldNameToField;
}

- (NSDictionary *) createJsonToSubmitForEvent:(Event *) event {

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

    WKBGeometry *geometry = [self getGeometry];
    [observationJson setObject:[GeometrySerializer serializeGeometry:geometry] forKey:@"geometry"];

    [observationJson setObject: [dateFormat stringFromDate:self.timestamp] forKey:@"timestamp"];

    NSMutableDictionary *jsonProperties = [[NSMutableDictionary alloc] initWithDictionary:self.properties];

    for (id key in self.properties) {
        id value = [self.properties objectForKey:key];
        id field = [[self fieldNameToFieldForEvent:event andFormId:0] objectForKey:key];
        if ([[field objectForKey:@"type"] isEqualToString:@"geometry"]) {
            WKBGeometry *fieldGeometry = value;
            [jsonProperties setObject:[GeometrySerializer serializeGeometry:fieldGeometry] forKey:key];
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

    NSDate *date = [NSDate dateFromIso8601String:[json objectForKey:@"lastModified"]];
    [self setLastModified:date];

    NSDate *timestamp = [NSDate dateFromIso8601String:[self.properties objectForKey:@"timestamp"]];
    [self setTimestamp:timestamp];

    [self setUrl:[json objectForKey:@"url"]];

    State state = [Observation  observationStateFromJson:json];
    [self setState:[NSNumber numberWithInt:(int) state]];

    WKBGeometry * geometry = [GeometryDeserializer parseGeometry:[json valueForKeyPath:@"geometry"]];
    [self setGeometry:geometry];

    return self;
}

- (NSDictionary *) generatePropertiesFromRaw: (NSDictionary *) propertyJson {
    Event *event = [Event getCurrentEventInContext:self.managedObjectContext];

    NSMutableDictionary *parsedProperties = [[NSMutableDictionary alloc] init];
    for (NSString* key in propertyJson) {
        
        if ([key isEqualToString:@"forms"]) {
            NSMutableArray *forms = [[NSMutableArray alloc] init];
            for (NSDictionary *formProperties in [propertyJson objectForKey:key]) {
                NSMutableDictionary *parsedFormProperties = [[NSMutableDictionary alloc] initWithDictionary:formProperties];
                NSDictionary *fields = [self fieldNameToFieldForEvent:event andFormId:[formProperties objectForKey:@"formId"]];
                for (id formKey in formProperties) {
                    id value = [formProperties objectForKey:formKey];
                    id field = [fields objectForKey:formKey];
                    if ([[field objectForKey:@"type"] isEqualToString:@"geometry"]) {
                        WKBGeometry * geometry = [GeometryDeserializer parseGeometry:value];
                        [parsedFormProperties setObject:geometry forKey:formKey];
                    }
                }
                [forms addObject:parsedFormProperties];

            }
            [parsedProperties setObject:forms forKey:key];
        } else {
            [parsedProperties setObject:[propertyJson objectForKey:key] forKey:key];
        }
        
    }

    return parsedProperties;
}

- (CLLocation *) location {
    WKBGeometry *geometry = [self getGeometry];
    WKBPoint *point = [GeometryUtility centroidOfGeometry:geometry];
    return [[CLLocation alloc] initWithLatitude:[point.y doubleValue] longitude:[point.x doubleValue]];
}

- (WKBGeometry *) getGeometry{
    WKBGeometry *geometry = nil;
    if(self.geometryData != nil){
        geometry = [GeometryUtility toGeometryFromGeometryData:self.geometryData];
    }
    return geometry;
}

- (void) setGeometry: (WKBGeometry *) geometry{
    NSData *data = nil;
    if(geometry != nil){
        data = [GeometryUtility toGeometryDataFromGeometry:geometry];
    }
    [self setGeometryData:data];
}

+(BOOL) checkIfRectangle: (NSArray<WKBPoint *> *) points{
    return [Observation checkIfRectangleAndFindSide:points] != nil;
}

+(NSNumber *) checkIfRectangleAndFindSide: (NSArray<WKBPoint *> *) points{
    NSNumber *sameXSide1 = nil;
    int size = (int)points.count;
    if (size == 4 || size == 5) {
        WKBPoint *point1 = [points objectAtIndex:0];
        WKBPoint *lastPoint = [points objectAtIndex:size - 1];
        BOOL closed = [point1.x isEqualToNumber:lastPoint.x] && [point1.y isEqualToNumber:lastPoint.y];
        if ((closed && size == 5) || (!closed && size == 4)) {
            WKBPoint *point2 = [points objectAtIndex:1];
            WKBPoint *point3 = [points objectAtIndex:2];
            WKBPoint *point4 = [points objectAtIndex:3];
            if ([point1.x isEqualToNumber:point2.x] && [point2.y isEqualToNumber:point3.y]) {
                if ([point1.y isEqualToNumber:point4.y] && [point3.x isEqualToNumber:point4.x]) {
                    sameXSide1 = [NSNumber numberWithInt:1];
                }
            } else if ([point1.y isEqualToNumber:point2.y] && [point2.x isEqualToNumber:point3.x]) {
                if ([point1.x isEqualToNumber:point4.x] && [point3.y isEqualToNumber:point4.y]) {
                    sameXSide1 = false;
                }
            }
        }
    }
    return sameXSide1;
}

+ (NSURLSessionDataTask *) operationToPushObservation:(Observation *) observation success:(void (^)(id)) success failure: (void (^)(NSError *)) failure {
    BOOL archived = observation.state != Archive;
    NSURLSessionDataTask *task = observation.remoteId ?
    (!archived ? [self operationToUpdateObservation:observation success:success failure:failure] : [self operationToDeleteObservation: observation success: success failure: failure] ):
        [self operationToCreateObservation:observation success:success failure:failure];

    return task;
}

+ (NSURLSessionDataTask *) operationToDeleteObservation:(Observation *) observation success:(void (^)(id)) success failure: (void (^)(NSError *)) failure {
    NSLog(@"Trying to delete observation %@", observation.url);
    NSURLSessionDataTask *task = [[MageSessionManager manager] POST_TASK:[NSString stringWithFormat:@"%@/states", observation.url] parameters: @{@"name":@"archive"} progress:^(NSProgress * _Nonnull uploadProgress) {
        NSLog(@"progress");
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        NSLog(@"success");
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"failure");
    }];
    
    return task;
}

+ (NSURLSessionDataTask *) operationToCreateObservation:(Observation *) observation success:(void (^)(id)) success failure: (void (^)(NSError *)) failure {
    NSString *url = [NSString stringWithFormat:@"%@/api/events/%@/observations/id", [MageServer baseURL], observation.eventId];
    NSLog(@"Trying to create observation %@", url);

    MageSessionManager *manager = [MageSessionManager manager];
    NSURLSessionDataTask *task = [manager POST_TASK:url parameters:nil progress:nil success:^(NSURLSessionTask *task, id response) {
        NSLog(@"Successfully created location for observation resource");

        // TODO create temp url to PUT to correct place until we upgrade server to 5.0
//        NSString *observationUrl = [response objectForKey:@"url"];
        NSString *remoteId = [response objectForKey:@"id"];
        NSString *observationUrl = [NSString stringWithFormat:@"%@/api/events/%@/observations/id/%@", [MageServer baseURL], observation.eventId, remoteId];

        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            Observation *localObservation = [observation MR_inContext:localContext];
            localObservation.remoteId = [response objectForKey:@"id"];
            localObservation.url = observationUrl;
        } completion:^(BOOL dbSuccess, NSError *error) {
            Event *event = [Event getCurrentEventInContext:observation.managedObjectContext];
            NSURLSessionDataTask *putTask = [manager PUT_TASK:observationUrl parameters:[observation createJsonToSubmitForEvent:event] success:^(NSURLSessionTask *task, id response) {
                if (success) {
                    success(response);
                }
            } failure:^(NSURLSessionTask *operation, NSError *error) {
                NSLog(@"Error: %@", error);
                failure(error);
            }];

            [manager addTask:putTask];
        }];

    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        failure(error);
    }];

    return task;
}

+ (NSURLSessionDataTask *) operationToUpdateObservation:(Observation *) observation success:(void (^)(id)) success failure: (void (^)(NSError *)) failure {
    NSLog(@"Trying to update observation %@", observation.url);
    Event *event = [Event getCurrentEventInContext:observation.managedObjectContext];
    NSURLSessionDataTask *task = [[MageSessionManager manager] PUT_TASK:observation.url parameters:[observation createJsonToSubmitForEvent:event] success:^(NSURLSessionTask *task, id response) {
        if (success) {
            success(response);
        }
    } failure:^(NSURLSessionTask *operation, NSError *error) {
        NSLog(@"Error: %@", error);
        failure(error);
    }];

    return task;
}

+ (NSURLSessionDataTask *) operationToPushFavorite:(ObservationFavorite *) favorite success:(void (^)(id)) success failure: (void (^)(NSError *)) failure {
    NSString *url = [NSString stringWithFormat:@"%@/api/events/%@/observations/%@/favorite", [MageServer baseURL], favorite.observation.eventId, favorite.observation.remoteId];
    NSLog(@"Trying to push favorite to server %@", url);

    MageSessionManager *manager = [MageSessionManager manager];

    NSURLSessionDataTask *task = nil;

    if (!favorite.favorite) {

        task = [manager DELETE_TASK:url parameters:nil success:^(NSURLSessionTask *task, id response) {
            if (success) {
                success(response);
            }
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            failure(error);
        }];

    }else{

        task = [manager PUT_TASK:url parameters:nil success:^(NSURLSessionTask *task, id response) {
            if (success) {
                success(response);
            }
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            failure(error);
        }];
    }

    return task;
}

+ (NSURLSessionDataTask *) operationToPushImportant:(ObservationImportant *) important success:(void (^)(id)) success failure: (void (^)(NSError *)) failure {
    NSString *url = [NSString stringWithFormat:@"%@/api/events/%@/observations/%@/important", [MageServer baseURL], important.observation.eventId, important.observation.remoteId];
    NSLog(@"Trying to push important to server %@", url);

    MageSessionManager *manager = [MageSessionManager manager];

    NSURLSessionDataTask *task = nil;

    if ([important.important isEqualToNumber:[NSNumber numberWithBool:YES]]) {
        NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
        [parameters setObject:important.reason forKey:@"description"];

        task = [manager PUT_TASK:url parameters:parameters success:^(NSURLSessionTask *task, id response) {
            if (success) {
                success(response);
            }
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            failure(error);
        }];

    } else {
        task = [manager DELETE_TASK:url parameters:nil success:^(NSURLSessionTask *task, id response) {
            if (success) {
                success(response);
            }
        } failure:^(NSURLSessionTask *operation, NSError *error) {
            NSLog(@"Error: %@", error);
            failure(error);
        }];
    }

    return task;
}

+ (NSURLSessionDataTask *) operationToPullInitialObservationsWithSuccess:(void (^) ()) success failure: (void(^)(NSError *)) failure {
    return [Observation operationToPullObservationsAsInitial:YES withSuccess:success failure:failure];
}

+ (NSURLSessionDataTask *) operationToPullObservationsWithSuccess:(void (^)())success failure:(void (^)(NSError *))failure {
    return [Observation operationToPullObservationsAsInitial:NO withSuccess:success failure:failure];
}

+ (NSURLSessionDataTask *) operationToPullObservationsAsInitial: (BOOL) initialPull withSuccess:(void (^) ()) success failure: (void(^)(NSError *)) failure {

    __block NSNumber *eventId = [Server currentEventId];
    NSString *url = [NSString stringWithFormat:@"%@/api/events/%@/observations", [MageServer baseURL], eventId];
    NSLog(@"Fetching observations from event %@", eventId);
    
    __block BOOL sendBulkNotification = initialPull;

    NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
    __block NSDate *lastObservationDate = [Observation fetchLastObservationDateInContext:[NSManagedObjectContext MR_defaultContext]];
    if (lastObservationDate != nil) {
        [parameters setObject:[lastObservationDate iso8601String] forKey:@"startDate"];
    }

    MageSessionManager *manager = [MageSessionManager manager];
    
    __block BOOL newData = NO;

    NSURLSessionDataTask *task = [manager GET_TASK:url parameters:parameters progress:nil success:^(NSURLSessionTask *task, id features) {
        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
            NSLog(@"Observation request complete");
            Event *event = [Event getEventById:eventId inContext:localContext];
            NSUInteger count = 0;
            for (id feature in features) {
                NSString *remoteId = [Observation observationIdFromJson:feature];
                State state = [Observation observationStateFromJson:feature];

                Observation *existingObservation = [Observation MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId == %@)", remoteId] inContext:localContext];
                // if the Observation is archived, delete it
                if (state == Archive && existingObservation) {
                    NSLog(@"Deleting archived observation with id: %@", remoteId);
                    [existingObservation MR_deleteEntity];
                    newData = YES;
                } else if (state != Archive && !existingObservation) {
                    // if the observation doesn't exist, insert it
                    Observation *observation = [Observation MR_createEntityInContext:localContext];
                    [observation populateObjectFromJson:feature];
                    observation.user = [User MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId = %@)", observation.userId] inContext:localContext];

                    NSDictionary *importantJson = [feature objectForKey:@"important"];
                    if (importantJson) {
                        ObservationImportant *important = [ObservationImportant importantForJson:importantJson inManagedObjectContext:localContext];
                        important.observation = observation;
                        observation.observationImportant = important;
                    }

                    for (NSString *userId in [feature objectForKey:@"favoriteUserIds"]) {
                        ObservationFavorite *favorite = [ObservationFavorite favoriteForUserId:userId inManagedObjectContext:localContext];
                        favorite.observation = observation;
                        [observation addFavoritesObject:favorite];
                    }

                    for (id attachmentJson in [feature objectForKey:@"attachments"]) {
                        Attachment *attachment = [Attachment attachmentForJson:attachmentJson inContext:localContext];
                        [observation addAttachmentsObject:attachment];
                    }

                    [observation setEventId:eventId];
                    NSLog(@"Saving new observation with id: %@", observation.remoteId);
                    count++;
                    if (!sendBulkNotification) {
                        [NotificationRequester observationPulled:observation];
                    }
                    newData = YES;
                } else if (state != Archive && ![existingObservation.dirty boolValue]) {

                    // if the observation is not dirty, and has been updated, update it
                    NSDate *lastModified = [NSDate dateFromIso8601String:[feature objectForKey:@"lastModified"]];
                    if ([lastModified compare:existingObservation.lastModified] == NSOrderedSame) {
                        // If the last modified date for this observation has not changed no need to update.
                        continue;
                    }

                    [existingObservation populateObjectFromJson:feature];
                    existingObservation.user = [User MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"(remoteId = %@)", existingObservation.userId] inContext:localContext];

                    NSDictionary *importantJson = [feature objectForKey:@"important"];
                    if (importantJson) {
                        ObservationImportant *important = [ObservationImportant importantForJson:importantJson inManagedObjectContext:localContext];
                        important.observation = existingObservation;
                        existingObservation.observationImportant = important;
                    } else {
                        if (existingObservation.observationImportant) {
                            [existingObservation.observationImportant MR_deleteEntityInContext:localContext];
                            existingObservation.observationImportant = nil;
                        }
                    }

                    NSDictionary *favoritesMap = [existingObservation getFavoritesMap];
                    NSArray *favoriteUserIds = [feature objectForKey:@"favoriteUserIds"];
                    for (NSString *userId in favoriteUserIds) {
                        ObservationFavorite *favorite = [favoritesMap objectForKey:userId];
                        if (!favorite) {
                            favorite = [ObservationFavorite favoriteForUserId:userId inManagedObjectContext:localContext];
                            favorite.observation = existingObservation;
                            [existingObservation addFavoritesObject:favorite];
                        }
                    }

                    for (ObservationFavorite *favorite in [favoritesMap allValues]) {
                        if (![favoriteUserIds containsObject:favorite.userId]) {
                            [favorite MR_deleteEntityInContext:localContext];
                            [existingObservation removeFavoritesObject:favorite];
                        }
                    }

                    for (id attachmentJson in [feature objectForKey:@"attachments"]) {
                        NSString *remoteId = [attachmentJson objectForKey:@"id"];
                        BOOL attachmentFound = NO;
                        for (Attachment *attachment in existingObservation.attachments) {
                            if (remoteId != nil && [remoteId isEqualToString:attachment.remoteId]) {
                                attachment.contentType = [attachmentJson objectForKey:@"contentType"];
                                attachment.name = [attachmentJson objectForKey:@"name"];
                                attachment.remotePath = [attachmentJson objectForKey:@"remotePath"];
                                attachment.size = [attachmentJson objectForKey:@"size"];
                                attachment.url = [attachmentJson objectForKey:@"url"];
                                attachment.observation = existingObservation;
                                attachmentFound = YES;
                                break;
                            }
                        }

                        if (!attachmentFound) {
                            Attachment *newAttachment = [Attachment attachmentForJson:attachmentJson inContext:localContext];
                            [existingObservation addAttachmentsObject:newAttachment];
                        }
                    }
                    [existingObservation setEventId:eventId];
                    newData = YES;
                    NSLog(@"Updating object with id: %@", existingObservation.remoteId);
                } else {
                    NSLog(@"Observation with id: %@ is dirty", remoteId);
                }
            }
            NSLog(@"Recieved %lu new observations and send bulk is %d", count, sendBulkNotification);
            if (sendBulkNotification && count > 0) {
                [NotificationRequester sendBulkNotificationCount: count inEvent: event];
            }
        } completion:^(BOOL successful, NSError *error) {
            if (!successful) {
                if (failure) {
                    failure(error);
                }
            } else if (success) {
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

- (void) shareObservationForViewController:(UIViewController *) viewController {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Downloading Attachments"
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleAlert];

    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    progressView.translatesAutoresizingMaskIntoConstraints = NO;
    [progressView setProgress:0.0];
    [alert.view addSubview:progressView];

    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:progressView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:alert.view attribute:NSLayoutAttributeTop multiplier:1 constant:80];
    NSLayoutConstraint *leftConstraint = [NSLayoutConstraint constraintWithItem:progressView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:alert.view attribute:NSLayoutAttributeLeading multiplier:1 constant:16];
    NSLayoutConstraint *rightConstraint = [NSLayoutConstraint constraintWithItem:alert.view attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:progressView attribute:NSLayoutAttributeTrailing multiplier:1 constant:16];
    [alert.view addConstraints:@[topConstraint, leftConstraint, rightConstraint]];

    // download the attachments (if we don't have them)
    MageSessionManager *manager = [MageSessionManager manager];

    dispatch_group_t group = dispatch_group_create();

    NSMutableArray *requests = [[NSMutableArray alloc] init];
    NSMutableArray *urls = [[NSMutableArray alloc] init];
    for (Attachment *attachment in self.attachments) {
        NSString *path = [NSTemporaryDirectory() stringByAppendingPathComponent:attachment.name];
        if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {

            NSURLRequest *request = [manager.requestSerializer requestWithMethod:@"GET" URLString:attachment.url parameters: nil error: nil];

            NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:^(NSProgress * downloadProgress){
                dispatch_async(dispatch_get_main_queue(), ^{
                    progressView.progress = downloadProgress.fractionCompleted;
                });
            } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                return [NSURL fileURLWithPath:path];
            } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {

                if(!error){
                    [urls addObject:filePath];
                }
                dispatch_group_leave(group);

            }];

            [requests addObject:task];
        } else {
            NSURL *url = [NSURL fileURLWithPath:path isDirectory:NO];
            [urls addObject:url];
        }
    }

    __block Boolean cancelled = NO;
    if ([requests count]) {
        [alert setMessage:[NSString stringWithFormat:@"1 of %lu\n\n", [requests count]]];

        [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            cancelled = YES;
            for (NSURLSessionDownloadTask *request in requests) {
                [request cancel];
            }
        }]];

        [viewController presentViewController:alert animated:YES completion:nil];
    }

    __weak typeof(self) weakSelf = self;
    for(NSURLSessionDownloadTask *request in requests){
        dispatch_group_enter(group);
        [manager addTask:request];
    }

    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [alert dismissViewControllerAnimated:YES completion:nil];

        if (cancelled) {
            // clean up attachments
            for (NSURL *url in urls) {
                [[NSFileManager defaultManager] removeItemAtURL:url error:nil];
            }

            return;
        }

        NSMutableArray *items = [[NSMutableArray alloc] init];
        [items addObject:[weakSelf observationText]];
        [items addObjectsFromArray:urls];

        UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
        [controller setValue:@"MAGE Observation" forKey:@"subject"];

        if (controller.popoverPresentationController) {
            controller.popoverPresentationController.sourceView = viewController.view;
            controller.popoverPresentationController.sourceRect = viewController.view.frame;
            controller.popoverPresentationController.permittedArrowDirections = 0;
        }

        [viewController presentViewController:controller animated:YES completion:nil];
    });

}

- (NSString *) observationText {
    Event *event = [self getEvent];
    
    NSDictionary *form = [event formForObservation:self];
    NSMutableArray *generalFields = [NSMutableArray arrayWithObjects:@"timestamp", @"geometry", @"type", nil];

    NSMutableString *text = [[NSMutableString alloc] init];

    NSMutableDictionary *nameToField = [[NSMutableDictionary alloc] init];
    for (NSDictionary *field in [form objectForKey:@"fields"]) {
        [nameToField setObject:field forKey:[field objectForKey:@"name"]];
    }

    // user
    [text appendFormat:@"Created by:\n%@\n\n", self.user.name];

    // timestamp
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateStyle = NSDateFormatterLongStyle;
    dateFormatter.timeStyle = NSDateFormatterLongStyle;
    [text appendFormat:@"Date:\n%@\n\n", [dateFormatter stringFromDate:self.timestamp]];

    // geometry
    WKBGeometry *geometry = [self getGeometry];
    WKBPoint *point = [GeometryUtility centroidOfGeometry:geometry];
    [text appendFormat:@"Latitude, Longitude:\n%f, %f\n\n", [point.y doubleValue], [point.x doubleValue]];

    // type
    [text appendString:[self propertyText:[self.properties objectForKey:@"type"] forField:[nameToField objectForKey:@"type"]]];

    // variant
    NSString *variantField = [form objectForKey:@"variantField"];;
    if (variantField) {
        [generalFields addObject:variantField];

        id variant = [self.properties objectForKey:variantField];
        if (variant) {
            [text appendString:[self propertyText:variant forField:[nameToField objectForKey:variantField]]];
        }
    }

    for (NSDictionary *field in [form objectForKey:@"fields"]) {
        if ([generalFields containsObject:[field objectForKey:@"name"]]) {
            continue;
        }

        if ([field objectForKey:@"archived"]) {
            continue;
        }

        id value = [self.properties objectForKey:[field objectForKey:@"name"]];
        if (![value length] || ([value isKindOfClass:[NSArray class]] && ![value count])) {
            continue;
        }

        [text appendString:[self propertyText:value forField:field]];
    }

    return text;
}

- (NSString *) propertyText:(id) property forField:(NSDictionary *) field {
    return [NSString stringWithFormat:@"%@:\n%@\n\n", [field objectForKey:@"title"], property];
}

- (Boolean) isDirty {
    return [self.dirty isEqualToNumber:[NSNumber numberWithBool:YES]];
}

- (Boolean) isImportant {
    return self.observationImportant != nil && [self.observationImportant.important isEqualToNumber:[NSNumber numberWithBool:YES]];
}

- (Boolean) currentUserCanUpdateImportant {
    User *currentUser = [User fetchCurrentUserInManagedObjectContext:self.managedObjectContext];
    
    // if the user has update on the event
    Event *event = [self getEvent];
    NSDictionary *acl = event.acl;
    NSDictionary *userAcl = [acl objectForKey:currentUser.remoteId];
    if (userAcl != nil) {
        if ([[userAcl objectForKey:@"permissions"] containsObject:@"update"]) {
            return YES;
        }
    }
    
    // if the user has DELETE_OBSERVATION permission
    Role *role = currentUser.role;
    NSArray *permissions = role.permissions;
    if ([permissions containsObject:@"UPDATE_EVENT"]) {
        return YES;
    }
    
    return NO;
}

- (Boolean) isDeletableByCurrentUser {
        
    User *currentUser = [User fetchCurrentUserInManagedObjectContext:self.managedObjectContext];
    
    // if the user has update on the event
    Event *event = [self getEvent];
    NSDictionary *acl = event.acl;
    NSDictionary *userAcl = [acl objectForKey:currentUser.remoteId];
    if (userAcl != nil) {
        if ([[userAcl objectForKey:@"permissions"] containsObject:@"update"]) {
            return YES;
        }
    }
    
    // if the user has DELETE_OBSERVATION permission
    Role *role = currentUser.role;
    NSArray *permissions = role.permissions;
    if ([permissions containsObject:@"DELETE_OBSERVATION"]) {
        return YES;
    }
    
    // If the observation was created by this user
    if ([currentUser.remoteId isEqualToString:self.user.remoteId]) {
        return YES;
    }
    
    return NO;
}

- (Boolean) hasValidationError {
    return [self.error objectForKey:kObservationErrorStatusCode] != nil;
}

- (NSString *) errorMessage {
    NSString *errorMessage = [self.error objectForKey:kObservationErrorMessage];
    if (!errorMessage) {
        errorMessage = [self.error objectForKey:kObservationErrorDescription];
    }

    return errorMessage;
}

- (void) deleteObservationWithCompletion: (nullable void (^)(BOOL contextDidSave, NSError * _Nullable error)) completion {
    if ([self isDeletableByCurrentUser]) {
        [self setState:[NSNumber numberWithInt:(int) Archive]];
        [self setDirty:[NSNumber numberWithBool:YES]];
        [self.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError * _Nullable error) {
            if (completion) {
                completion(contextDidSave, error);
            }
        }];
    }
}

- (void) toggleFavoriteWithCompletion:(nullable void (^)(BOOL contextDidSave, NSError * _Nullable error)) completion {
    NSManagedObjectContext *context = self.managedObjectContext;
    User *user = [User fetchCurrentUserInManagedObjectContext:context];
    ObservationFavorite *favorite = [[self getFavoritesMap] objectForKey:user.remoteId];

    NSLog(@"toggle favorite %@", favorite);
    if (favorite && favorite.favorite) {
        // toggle off
        favorite.dirty = YES;
        favorite.favorite = NO;
    } else {
        // toggle on
        if (!favorite) {
            favorite = [ObservationFavorite MR_createEntityInContext:context];
            [self addFavoritesObject:favorite];
            favorite.observation = self;
        }

        favorite.dirty = YES;
        favorite.favorite = YES;
        favorite.userId = user.remoteId;
    }

    [context MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError * _Nullable error) {
        if (completion) {
            completion(contextDidSave, error);
        };
    }];
}

- (NSDictionary *) getFavoritesMap {
    NSMutableDictionary *favorites = [[NSMutableDictionary alloc] init];
    for (ObservationFavorite *favorite in self.favorites) {
        [favorites setObject:favorite forKey:favorite.userId];
    }

    return favorites;
}

- (void) flagImportantWithDescription:(NSString *) description completion:(nullable void (^)(BOOL contextDidSave, NSError * _Nullable error)) completion {
    if (![self currentUserCanUpdateImportant]) {
        if (completion) {
            completion(NO, nil);
        };
        return;
    }
    NSManagedObjectContext *context = self.managedObjectContext;
    User *currentUser = [User fetchCurrentUserInManagedObjectContext:context];

    ObservationImportant *important = self.observationImportant;
    if (!important) {
        important = [ObservationImportant MR_createEntityInContext:context];
        important.observation = self;
        self.observationImportant = important;
    }

    important.dirty = [NSNumber numberWithBool:YES];
    important.important = [NSNumber numberWithBool:YES];
    important.userId = currentUser.remoteId;
    important.reason = description;

    // This will get overriden by the server, but lets set an inital value
    // so the UI has something to display
    important.timestamp = [NSDate date];

    [context MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError * _Nullable error) {
        if (completion) {
            completion(contextDidSave, error);
        };
    }];
}

- (void) removeImportantWithCompletion:(nullable void (^)(BOOL contextDidSave, NSError * _Nullable error)) completion {
    if (![self currentUserCanUpdateImportant]) {
        if (completion) {
            completion(NO, nil);
        };
        return;
    }
    NSManagedObjectContext *context = self.managedObjectContext;

    ObservationImportant *important = self.observationImportant;
    if (important) {
        important.dirty = [NSNumber numberWithBool:YES];
        important.important = [NSNumber numberWithBool:NO];
    }

    [context MR_saveToPersistentStoreWithCompletion:^(BOOL contextDidSave, NSError * _Nullable error) {
        if (completion) {
            completion(contextDidSave, error);
        };
    }];
}

+ (NSDate *) fetchLastObservationDateInContext:(NSManagedObjectContext *) context {
    NSDate *date = nil;
    User *user = [User fetchCurrentUserInManagedObjectContext:context];
    Observation *observation = [Observation MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"eventId == %@ AND user.remoteId != %@", [Server currentEventId], user.remoteId]
                                                             sortedBy:@"lastModified"
                                                            ascending:NO inContext:context];
    if (observation) {
        date = observation.lastModified;
    }

    return date;
}

@end

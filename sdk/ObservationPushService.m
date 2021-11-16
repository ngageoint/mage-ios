//
//  ObservationPushService.m
//  mage-ios-sdk
//
//

#import "ObservationPushService.h"
#import "MageSessionManager.h"
#import "DataConnectionUtilities.h"
#import "MageServer.h"
#import "MAGE-Swift.h"

NSString * const kObservationPushFrequencyKey = @"observationPushFrequency";
NSString * const kObservationErrorStatusCode = @"errorStatusCode";
NSString * const kObservationErrorDescription = @"errorDescription";
NSString * const kObservationErrorMessage = @"errorMessage";

@interface ObservationPushService () <NSFetchedResultsControllerDelegate>
@property (nonatomic) NSTimeInterval interval;
@property (nonatomic, strong) NSMutableSet<id<ObservationPushDelegate>>* delegates;
@property (nonatomic, strong) NSTimer* observationPushTimer;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSFetchedResultsController *favoritesFetchedResultsController;
@property (nonatomic, strong) NSFetchedResultsController *importantFetchedResultsController;
@property (nonatomic, strong) NSMutableDictionary *pushingObservations;
@property (nonatomic, strong) NSMutableDictionary *pushingFavorites;
@property (nonatomic, strong) NSMutableDictionary *pushingImportant;
@end

@implementation ObservationPushService

+ (instancetype) singleton {
    static ObservationPushService *pushService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pushService = [[self alloc] init];
    });
    return pushService;
}

- (id) init {
    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        _interval = [[defaults valueForKey:kObservationPushFrequencyKey] doubleValue];
        _pushingObservations = [[NSMutableDictionary alloc] init];
        _pushingFavorites = [[NSMutableDictionary alloc] init];
        _pushingImportant = [[NSMutableDictionary alloc] init];
        _delegates = [NSMutableSet set];
    }
    
    return self;
}

- (BOOL) isPushingFavorites {
    return _pushingFavorites.allKeys.count != 0;
}

- (BOOL) isPushingObservations {
    return _pushingObservations.allKeys.count != 0;
}

- (BOOL) isPushingImportant {
    return _pushingImportant.allKeys.count != 0;
}

- (void) addObservationPushDelegate:(id<ObservationPushDelegate>) delegate {
    [self.delegates addObject:delegate];
}

- (void) removeObservationPushDelegate:(id<ObservationPushDelegate>) delegate {
    [self.delegates removeObject:delegate];
}

- (void) start {
    NSLog(@"start pushing observations");
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    
    self.fetchedResultsController = [Observation MR_fetchAllSortedBy:@"timestamp"
                                                           ascending:NO
                                                       withPredicate:[NSPredicate predicateWithFormat:@"dirty == YES"]
                                                             groupBy:nil
                                                            delegate:self
                                                           inContext:context];
        
    self.favoritesFetchedResultsController = [ObservationFavorite MR_fetchAllSortedBy:@"observation.timestamp"
                                                           ascending:NO
                                                       withPredicate:[NSPredicate predicateWithFormat:@"dirty == YES"]
                                                             groupBy:nil
                                                            delegate:self
                                                           inContext:context];
    
    self.importantFetchedResultsController = [ObservationImportant MR_fetchAllSortedBy:@"observation.timestamp"
                                                                            ascending:NO
                                                                        withPredicate:[NSPredicate predicateWithFormat:@"dirty == YES"]
                                                                              groupBy:nil
                                                                             delegate:self
                                                                            inContext:context];
    
    [self onTimerFire];
    [self scheduleTimer];
}


- (void) scheduleTimer {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([weakSelf.observationPushTimer isValid]) {
            [weakSelf.observationPushTimer invalidate];
            weakSelf.observationPushTimer = nil;
        }
        weakSelf.observationPushTimer = [NSTimer scheduledTimerWithTimeInterval:weakSelf.interval target:self selector:@selector(onTimerFire) userInfo:nil repeats:YES];
    });
}

- (void) onTimerFire {
    if (![[UserUtility singleton] isTokenExpired] && [DataConnectionUtilities shouldPushObservations]) {
        [self pushObservations:self.fetchedResultsController.fetchedObjects];
        [self pushFavorites:self.favoritesFetchedResultsController.fetchedObjects];
        [self pushImportant:self.importantFetchedResultsController.fetchedObjects];
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id) anObject atIndexPath:(NSIndexPath *) indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *) newIndexPath {
    if ([anObject isKindOfClass:[Observation class]]) {
        switch(type) {
            case NSFetchedResultsChangeInsert: {
                NSLog(@"observations inserted, push em");
                [self pushObservations:@[anObject]];
                break;
            }
            case NSFetchedResultsChangeDelete:
                break;
            case NSFetchedResultsChangeUpdate: {
                NSLog(@"observations updated, push em");
                if ([anObject remoteId]) [self pushObservations:@[anObject]];
                break;
            }
            case NSFetchedResultsChangeMove:
                break;
        }
    } else if ([anObject isKindOfClass:[ObservationFavorite class]]) {
        switch(type) {
            case NSFetchedResultsChangeInsert: {
                NSLog(@"favorites inserted, push em");
                [self pushFavorites:@[anObject]];
                break;
            }
            case NSFetchedResultsChangeDelete:
                break;
            case NSFetchedResultsChangeUpdate: {
                NSLog(@"favorites updated, push em");
                if ([[anObject observation] remoteId]) [self pushFavorites:@[anObject]];
                break;
            }
            case NSFetchedResultsChangeMove:
                break;
        }
    } else if ([anObject isKindOfClass:[ObservationImportant class]]) {
        switch(type) {
            case NSFetchedResultsChangeInsert: {
                NSLog(@"important inserted, push em %@", anObject);
                if ([[anObject observation] remoteId]) [self pushImportant:@[anObject]];
                break;
            }
            case NSFetchedResultsChangeDelete: {
                break;
            }
            case NSFetchedResultsChangeUpdate: {
                NSLog(@"important updated, push em %@", anObject);
                if ([[anObject observation] remoteId]) [self pushImportant:@[anObject]];
                break;
            }
            case NSFetchedResultsChangeMove:
            break;
        }
    }
}

- (void) pushObservations:(NSArray *) observations {
    if (![DataConnectionUtilities shouldPushObservations]) return;
    NSLog(@"currently still pushing %lu observations", (unsigned long) self.pushingObservations.count);

    // only push observations that haven't already been told to be pushed
    NSMutableDictionary *observationsToPush = [[NSMutableDictionary alloc] init];
    for (Observation *observation in observations) {
        [[observation managedObjectContext] obtainPermanentIDsForObjects:@[observation] error:nil];
        
        if ([self.pushingObservations objectForKey:observation.objectID] == nil) {
            [self.pushingObservations setObject:observation forKey:observation.objectID];
            [observationsToPush setObject:observation forKey:observation.objectID];
            observation.syncing = YES;
        }
    }
    
    NSLog(@"about to push an additional %lu observations", (unsigned long) observationsToPush.count);
    __weak typeof(self) weakSelf = self;
    MageSessionManager *manager = [MageSessionManager sharedManager];
    for (Observation *observation in [observationsToPush allValues]) {
        NSManagedObjectID *observationID = observation.objectID;
        NSURLSessionDataTask *observationPushTask = [Observation operationToPushObservationWithObservation:observation success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable response) {
            NSLog(@"Successfully submitted observation");
            // TODO: handle if response is null
            // save the properties of the observation before they get overwritten so we can match the attachments later
            NSDictionary *propertiesToSave = [NSDictionary dictionaryWithDictionary:observation.properties];
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                Observation *localObservation = [observation MR_inContext:localContext];
                [localObservation populateWithJson:response];
                localObservation.dirty = false;
                localObservation.error = nil;
                
                if ([MageServer isServerVersion5]) {
                    for (Attachment *attachment in localObservation.attachments) {
                        attachment.observationRemoteId = localObservation.remoteId;
                    }
                } else {
                    // when the observation comes back from a new server the attachments will have moved from the field to the attachments array
                    for (NSDictionary *attachmentResponse in response[@"attachments"]) {
                        // only look for attachments without a url that match a field we tried to save
                        if ([attachmentResponse valueForKey:@"url"] == nil) {
                            NSString *fieldName = [attachmentResponse valueForKey:@"fieldName"];
                            NSString *name = [attachmentResponse valueForKey:@"name"];
                            NSArray *forms = [propertiesToSave objectForKey:@"forms"];
                            if (forms != nil) {
                                // search through each form for attachments that needed saving
                                for (NSDictionary *form in forms) {
                                    if ([form objectForKey:fieldName] != nil) {
                                        // name will be unique because when the attachment is pulled in, we rename it to MAGE_yyyyMMdd_HHmmss.extension
                                        NSArray *unfilteredFieldAttachments = [form objectForKey:fieldName];
                                        if (unfilteredFieldAttachments != nil && [unfilteredFieldAttachments isKindOfClass:[NSArray class]]) {
                                            NSArray *fieldAttachments = [unfilteredFieldAttachments filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"name == %@", name]];
                                            if ([fieldAttachments count] != 0) {
                                                NSDictionary *fieldAttachment = fieldAttachments[0];
                                                Attachment *attachment = [Attachment attachmentWithJson:attachmentResponse context:localContext];
                                                [attachment setObservation:localObservation];
                                                [attachment setObservationRemoteId: localObservation.remoteId];
                                                [attachment setDirty:true];
                                                [attachment setLocalPath:[fieldAttachment valueForKey:@"localPath"]];
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            } completion:^(BOOL success, NSError *error) {

                [weakSelf.pushingObservations removeObjectForKey:observationID];
                
                for (id<ObservationPushDelegate> delegate in self.delegates) {
                    [delegate didPushObservation:observation success:success error:error];
                }
            }];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * error) {
            NSLog(@"Error submitting observation");
            // TODO check for 400
            if (error == nil) {
                NSLog(@"Error submitting observation, no error returned");

                [weakSelf.pushingObservations removeObjectForKey:observationID];
                for (id<ObservationPushDelegate> delegate in weakSelf.delegates) {
                    [delegate didPushObservation:observation success:NO error:error];
                }
                
                return;
            }
                        
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                Observation *localObservation = [observation MR_inContext:localContext];
                
                NSHTTPURLResponse *response = error.userInfo[AFNetworkingOperationFailingURLResponseErrorKey];
                
                NSMutableDictionary *localError = localObservation.error ? [localObservation.error mutableCopy] : [NSMutableDictionary dictionary];
                [localError setObject:[error localizedDescription] forKey:kObservationErrorDescription];
                
                if (response) {
                    [localError setObject:[NSNumber numberWithInteger:response.statusCode] forKey:kObservationErrorStatusCode];
                    [localError setObject:[[NSString alloc] initWithData:(NSData *) error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey] encoding:NSUTF8StringEncoding] forKey:kObservationErrorMessage];
                }
                
                localObservation.error = localError;
                // TODO if we set the error, the push service sees it as an update so it tries to resend immediately
                // we need to put in some kind of throttle
            } completion:^(BOOL success, NSError *coreDataError) {
                [weakSelf.pushingObservations removeObjectForKey:observationID];
                
                for (id<ObservationPushDelegate> delegate in weakSelf.delegates) {
                    [delegate didPushObservation:observation success:NO error:error];
                }
            }];
        }];
        if (observationPushTask != nil) {
            [manager addTask:observationPushTask];
        }
    }
}

- (void) pushFavorites:(NSArray *) favorites {
    if (![DataConnectionUtilities shouldPushObservations]) return;
    NSLog(@"currently still pushing %lu favorites", (unsigned long) self.pushingFavorites.count);
    
    // only push favorites that haven't already been told to be pushed
    NSMutableDictionary *favoritesToPush = [[NSMutableDictionary alloc] init];
    for (ObservationFavorite *favorite in favorites) {
        if ([self.pushingFavorites objectForKey:favorite.objectID] == nil) {
            [self.pushingFavorites setObject:favorite forKey:favorite.objectID];
            [favoritesToPush setObject:favorite forKey:favorite.objectID];
        }
    }
    
    NSLog(@"about to push an additional %lu favorites", (unsigned long) favoritesToPush.count);
    __weak typeof(self) weakSelf = self;
    MageSessionManager *manager = [MageSessionManager sharedManager];
    for (ObservationFavorite *favorite in [favoritesToPush allValues]) {
        NSURLSessionDataTask *favoritePushTask = [Observation operationToPushFavoriteWithFavorite:favorite success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable response) {
            NSLog(@"Successfully submitted favorite");
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                ObservationFavorite *localFavorite = [favorite MR_inContext:localContext];
                localFavorite.dirty = false;
            } completion:^(BOOL success, NSError *error) {
                [weakSelf.pushingFavorites removeObjectForKey:favorite.objectID];
            }];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"Error submitting favorite");
            [weakSelf.pushingFavorites removeObjectForKey:favorite.objectID];
        }];
        [manager addTask:favoritePushTask];
    }
}

- (void) pushImportant:(NSArray *) importants {
    if (![DataConnectionUtilities shouldPushObservations]) return;
    NSLog(@"currently still pushing %lu important changes", (unsigned long) self.pushingImportant.count);
    
    // only push important changes that haven't already been told to be pushed
    NSMutableDictionary *importantsToPush = [[NSMutableDictionary alloc] init];
    for (ObservationImportant *important in importants) {
        if (important.observation.remoteId != nil && [self.pushingImportant objectForKey:important.observation.remoteId] == nil) {
            NSLog(@"adding important to push %@", important.observation.remoteId);
            [self.pushingImportant setObject:important forKey:important.observation.remoteId];
            [importantsToPush setObject:important forKey:important.observation.remoteId];
        }
    }
    
    NSLog(@"about to push an additional %lu importants", (unsigned long) importantsToPush.count);
    __weak typeof(self) weakSelf = self;
    MageSessionManager *manager = [MageSessionManager sharedManager];
    for (NSString *observationId in importantsToPush) {
        ObservationImportant *important = importantsToPush[observationId];
        NSURLSessionDataTask *importantPushTask = [Observation operationToPushImportantWithImportant:important success:^(NSURLSessionDataTask * _Nonnull task, id _Nullable response) {
            // verify that the current state in our data is the same as returned from the server
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                ObservationImportant *localImportant = [important MR_inContext:localContext];
                BOOL serverImportant = response[@"important"] != nil;
                if (localImportant.important == serverImportant) {
                    localImportant.dirty = false;
                } else {
                    // force a push again
                    localImportant.timestamp = [NSDate date];
                }
                [localImportant.managedObjectContext refreshObject:localImportant.observation mergeChanges:false];
            } completion:^(BOOL success, NSError *error) {
                [weakSelf.pushingImportant removeObjectForKey:observationId];
            }];
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"Error submitting important");
            [weakSelf.pushingImportant removeObjectForKey:observationId];
        }];
        [manager addTask:importantPushTask];
    }
}

-(void) stop {
    NSLog(@"stop pushing observations");
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([weakSelf.observationPushTimer isValid]) {
            [weakSelf.observationPushTimer invalidate];
            weakSelf.observationPushTimer = nil;
        }
    });

    self.fetchedResultsController = nil;
    self.importantFetchedResultsController = nil;
    self.favoritesFetchedResultsController = nil;
}


@end

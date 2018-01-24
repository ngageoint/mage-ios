//
//  ObservationPushService.m
//  mage-ios-sdk
//
//

#import "ObservationPushService.h"
#import "MageSessionManager.h"
#import "Observation.h"
#import "ObservationFavorite.h"
#import "ObservationImportant.h"
#import "Attachment.h"
#import "UserUtility.h"

NSString * const kObservationPushFrequencyKey = @"observationPushFrequency";

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
        _delegates = [NSMutableSet set];
    }
    
    return self;
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
    
    [self pushObservations:self.fetchedResultsController.fetchedObjects];
    
    self.favoritesFetchedResultsController = [ObservationFavorite MR_fetchAllSortedBy:@"observation.timestamp"
                                                           ascending:NO
                                                       withPredicate:[NSPredicate predicateWithFormat:@"dirty == YES"]
                                                             groupBy:nil
                                                            delegate:self
                                                           inContext:context];
    
    [self pushFavorites:self.favoritesFetchedResultsController.fetchedObjects];
    
    self.importantFetchedResultsController = [ObservationImportant MR_fetchAllSortedBy:@"observation.timestamp"
                                                                            ascending:NO
                                                                        withPredicate:[NSPredicate predicateWithFormat:@"dirty == YES"]
                                                                              groupBy:nil
                                                                             delegate:self
                                                                            inContext:context];
    
    [self pushImportant:self.importantFetchedResultsController.fetchedObjects];

    
    [self scheduleTimer];
}

- (void) scheduleTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_observationPushTimer isValid]) {
            [_observationPushTimer invalidate];
            _observationPushTimer = nil;
        }
        self.observationPushTimer = [NSTimer scheduledTimerWithTimeInterval:self.interval target:self selector:@selector(onTimerFire) userInfo:nil repeats:YES];
    });
}

- (void) onTimerFire {
    if (![[UserUtility singleton] isTokenExpired]) {
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
                NSLog(@"favorites deleted, push em");
                if ([[anObject observation] remoteId]) [self pushFavorites:@[anObject]];
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
                NSLog(@"important inserted, push em");
                [self pushImportant:@[anObject]];
                break;
            }
            case NSFetchedResultsChangeDelete: {
                NSLog(@"important deleted, push em");
                if ([[anObject observation] remoteId]) [self pushImportant:@[anObject]];
                break;
            }
            case NSFetchedResultsChangeUpdate: {
                NSLog(@"important updated, push em");
                if ([[anObject observation] remoteId]) [self pushImportant:@[anObject]];
                break;
            }
            case NSFetchedResultsChangeMove:
            break;
        }
    }
}

- (void) pushObservations:(NSArray *) observations {
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
    MageSessionManager *manager = [MageSessionManager manager];
    for (Observation *observation in [observationsToPush allValues]) {
        NSLog(@"submitting observation %@", observation.remoteId);
        NSURLSessionDataTask *observationPushTask = [Observation operationToPushObservation:observation success:^(id response) {
            NSLog(@"Successfully submitted observation");
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                Observation *localObservation = [observation MR_inContext:localContext];
                [localObservation populateObjectFromJson:response];
                localObservation.dirty = [NSNumber numberWithBool:NO];
                localObservation.error = nil;
                
                for (Attachment *attachment in localObservation.attachments) {
                    attachment.observationRemoteId = localObservation.remoteId;
                }
            } completion:^(BOOL success, NSError *error) {
                [weakSelf.pushingObservations removeObjectForKey:observation.objectID];
                
                for (id<ObservationPushDelegate> delegate in self.delegates) {
                    [delegate didPushObservation:observation success:success error:error];
                }
            }];
        } failure:^(NSError* error) {
            NSLog(@"Error submitting observation");
            // TODO check for 400
            if (error == nil) {
                NSLog(@"Error submitting observation, no error returned");
                
                [weakSelf.pushingObservations removeObjectForKey:observation.objectID];
                
                for (id<ObservationPushDelegate> delegate in self.delegates) {
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
            } completion:^(BOOL success, NSError *coreDataError) {
                [weakSelf.pushingObservations removeObjectForKey:observation.objectID];
                
                for (id<ObservationPushDelegate> delegate in self.delegates) {
                    [delegate didPushObservation:observation success:NO error:error];
                }
            }];
        }];
        
        [manager addTask:observationPushTask];
    }
}

- (void) pushFavorites:(NSArray *) favorites {
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
    MageSessionManager *manager = [MageSessionManager manager];
    for (ObservationFavorite *favorite in [favoritesToPush allValues]) {
        NSURLSessionDataTask *favoritePushTask = [Observation operationToPushFavorite:favorite success:^(id response) {
            NSLog(@"Successfully submitted favorite");
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                ObservationFavorite *localFavorite = [favorite MR_inContext:localContext];
                localFavorite.dirty = NO;
            } completion:^(BOOL success, NSError *error) {
                [weakSelf.pushingFavorites removeObjectForKey:favorite.objectID];
            }];
        } failure:^(NSError* error) {
            NSLog(@"Error submitting favorite");
            [weakSelf.pushingFavorites removeObjectForKey:favorite.objectID];
        }];
        
        [manager addTask:favoritePushTask];
    }
}

- (void) pushImportant:(NSArray *) importants {
    NSLog(@"currently still pushing %lu important changes", (unsigned long) self.pushingImportant.count);
    
    // only push important changes that haven't already been told to be pushed
    NSMutableDictionary *importantsToPush = [[NSMutableDictionary alloc] init];
    for (ObservationImportant *important in importants) {
        if ([self.pushingImportant objectForKey:important.objectID] == nil) {
            [self.pushingImportant setObject:important forKey:important.objectID];
            [importantsToPush setObject:important forKey:important.objectID];
        }
    }
    
    NSLog(@"about to push an additional %lu importants", (unsigned long) importantsToPush.count);
    __weak typeof(self) weakSelf = self;
    MageSessionManager *manager = [MageSessionManager manager];
    for (ObservationImportant *important in [importantsToPush allValues]) {
        NSURLSessionDataTask *importantPushTask = [Observation operationToPushImportant:important success:^(id response) {
            NSLog(@"Successfully submitted important");
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                ObservationImportant *localImportant = [important MR_inContext:localContext];
                localImportant.dirty = [NSNumber numberWithBool:NO];
            } completion:^(BOOL success, NSError *error) {
                [weakSelf.pushingImportant removeObjectForKey:important.objectID];
            }];
        } failure:^(NSError* error) {
            NSLog(@"Error submitting important");
            [weakSelf.pushingFavorites removeObjectForKey:important.objectID];
        }];
        
        [manager addTask:importantPushTask];
    }
}

-(void) stop {
    NSLog(@"stop pushing observations");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_observationPushTimer isValid]) {
            [_observationPushTimer invalidate];
            _observationPushTimer = nil;
        }
    });

    self.fetchedResultsController = nil;
}


@end

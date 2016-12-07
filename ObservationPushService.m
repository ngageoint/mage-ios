//
//  ObservationPushService.m
//  mage-ios-sdk
//
//

#import "ObservationPushService.h"
#import "HttpManager.h"
#import "Observation.h"
#import "Attachment.h"
#import "UserUtility.h"

NSString * const kObservationPushFrequencyKey = @"observationPushFrequency";

@interface ObservationPushService () <NSFetchedResultsControllerDelegate>
@property (nonatomic) NSTimeInterval interval;
@property (nonatomic, strong) NSTimer* observationPushTimer;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableDictionary *pushingObservations;
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
    }
    
    return self;
}

- (void) start {
    NSLog(@"start pushing observations");
    
    self.fetchedResultsController = [Observation MR_fetchAllSortedBy:@"timestamp"
                                                           ascending:NO
                                                       withPredicate:[NSPredicate predicateWithFormat:@"dirty == YES"]
                                                             groupBy:nil
                                                            delegate:self
                                                           inContext:[NSManagedObjectContext MR_defaultContext]];
    
    [self pushObservations:self.fetchedResultsController.fetchedObjects];
    
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
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id) anObject atIndexPath:(NSIndexPath *) indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *) newIndexPath {
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
            Observation *observation = anObject;
            if (observation.remoteId) [self pushObservations:@[anObject]];
            break;
        }
        case NSFetchedResultsChangeMove:
            break;
    }
}


- (void) pushObservations:(NSArray *) observations {
    NSLog(@"currently still pushing %lu observations", (unsigned long)self.pushingObservations.count);
    
    // only push observations that haven't already been told to be pushed
    NSMutableDictionary *observationsToPush = [[NSMutableDictionary alloc] init];
    for (Observation *observation in observations) {
        if ([self.pushingObservations objectForKey:observation.objectID] == nil){
            [self.pushingObservations setObject:observation forKey:observation.objectID];
            [observationsToPush setObject:observation forKey:observation.objectID];
        }
    }
    
    NSLog(@"about to push an additional %lu observations", (unsigned long) observationsToPush.count);
    __weak ObservationPushService *weakSelf = self;
    for (Observation *observation in [observationsToPush allValues]) {
        NSLog(@"submitting observation %@", observation.remoteId);
        NSOperation *observationPushOperation = [Observation operationToPushObservation:observation success:^(id response) {
            NSLog(@"Successfully submitted observation");
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
                Observation *localObservation = [observation MR_inContext:localContext];
                [localObservation populateObjectFromJson:response];
                localObservation.dirty = [NSNumber numberWithBool:NO];
                
                for (Attachment *attachment in localObservation.attachments) {
                    attachment.observationRemoteId = localObservation.remoteId;
                }
            } completion:^(BOOL success, NSError *error) {
                [weakSelf.pushingObservations removeObjectForKey:observation.objectID];

            }];
        } failure:^(NSError* error) {
            NSLog(@"Error submitting observation");
            [weakSelf.pushingObservations removeObjectForKey:observation.objectID];
        }];
        
        [[HttpManager singleton].manager.operationQueue addOperation:observationPushOperation];
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

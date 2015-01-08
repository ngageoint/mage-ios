//
//  ObservationPushService.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 10/31/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "ObservationPushService.h"
#import "HttpManager.h"
#import "Observation+helper.h"
#import "Attachment.h"

NSString * const kObservationPushFrequencyKey = @"observationPushFrequency";

@interface ObservationPushService () <NSFetchedResultsControllerDelegate>
@property (nonatomic) NSTimeInterval interval;
@property (nonatomic, strong) NSTimer* observationPushTimer;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableDictionary *pushingObservations;
@end

@implementation ObservationPushService

- (id) initWithManagedObjectContext:(NSManagedObjectContext *) managedObjectContext {
    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        _interval = [[defaults valueForKey:kObservationPushFrequencyKey] doubleValue];
        _pushingObservations = [[NSMutableDictionary alloc] init];
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:kObservationPushFrequencyKey
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
        
        self.fetchedResultsController = [Observation MR_fetchAllSortedBy:@"timestamp"
                                                               ascending:NO
                                                           withPredicate:[NSPredicate predicateWithFormat:@"dirty == YES"]
                                                                 groupBy:nil
                                                                delegate:nil
                                                               inContext:managedObjectContext];
    }
    
    return self;
}

- (void) start {
    [self stop];
    
    self.fetchedResultsController.delegate = self;
    [self pushObservations:self.fetchedResultsController.fetchedObjects];
    
    [self scheduleTimer];
}

- (void) scheduleTimer {
    self.observationPushTimer = [NSTimer timerWithTimeInterval:self.interval target:self selector:@selector(onTimerFire) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.observationPushTimer forMode:NSRunLoopCommonModes];
}

- (void) onTimerFire {
    [self pushObservations:self.fetchedResultsController.fetchedObjects];
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
        case NSFetchedResultsChangeUpdate:
            NSLog(@"observations updated, push em");
            [self pushObservations:@[anObject]];
            break;
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
        NSLog(@"submitting observation %@", observation);
        NSOperation *observationPushOperation = [Observation operationToPushObservation:observation success:^(id response) {
            NSLog(@"Successfully submitted observation");
            [observation populateObjectFromJson:response];
            observation.dirty = [NSNumber numberWithBool:NO];
            
            for (Attachment *attachment in observation.attachments) {
                attachment.observationRemoteId = observation.remoteId;
            }
            [weakSelf.fetchedResultsController.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                [weakSelf.pushingObservations removeObjectForKey:observation.objectID];
            }];
        } failure:^{
            NSLog(@"Error submitting observation");
            [weakSelf.pushingObservations removeObjectForKey:observation.objectID];
        }];
        
        [[HttpManager singleton].manager.operationQueue addOperation:observationPushOperation];
    }
}

-(void) stop {
    if ([_observationPushTimer isValid]) {
        [_observationPushTimer invalidate];
        _observationPushTimer = nil;
    }
    
    self.fetchedResultsController.delegate = nil;
}

@end

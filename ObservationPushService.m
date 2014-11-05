//
//  ObservationPushService.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 10/31/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "ObservationPushService.h"
#import "HttpManager.h"
#import "NSManagedObjectContext+MAGE.h"
#import "Observation+helper.h"

NSString * const kObservationPushFrequencyKey = @"observationPushFrequency";

@interface ObservationPushService () <NSFetchedResultsControllerDelegate>
@property (nonatomic) NSTimeInterval interval;
@property (nonatomic, strong) NSTimer* observationPushTimer;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) NSMutableDictionary *pushingObservations;
@end

@implementation ObservationPushService

- (id) init {
    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        _interval = [[defaults valueForKey:kObservationPushFrequencyKey] doubleValue];
        _pushingObservations = [[NSMutableDictionary alloc] init];
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:kObservationPushFrequencyKey
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
        
        NSManagedObjectContext *context = [NSManagedObjectContext defaultManagedObjectContext];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"Observation" inManagedObjectContext:context]];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO], nil]];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"dirty == YES"]];

        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                   managedObjectContext:context
                                                                                                     sectionNameKeyPath:@"sectionName"
                                                                                                              cacheName:nil];
        [self.fetchedResultsController setDelegate:self];
    }
    
    return self;
}

- (void) start {
    [self stop];
    
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
    
    [self pushObservations];
    // probably not exactly correct but for now i am just going to schedule right here
    // should wait for things to push and then schedule again maybe.
    [self scheduleTimer];
}

- (void) scheduleTimer {
    self.observationPushTimer = [NSTimer timerWithTimeInterval:self.interval target:self selector:@selector(onTimerFire) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:self.observationPushTimer forMode:NSRunLoopCommonModes];
}

- (void) onTimerFire {
    [self pushObservations];
}


//controllerWillChangeContent:
//controller:didChangeObject:atIndexPath:forChangeType:newIndexPath:
//controller:didChangeSection:atIndex:forChangeType:
//controllerDidChangeContent:

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller {
   
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id) anObject atIndexPath:(NSIndexPath *) indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *) newIndexPath {
    
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
//            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            NSLog(@"observations inserted, push em");
            [self pushObservations];
            break;
            
        case NSFetchedResultsChangeDelete:
//            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
//            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            NSLog(@"observations updated, push em");
            [self pushObservations];
            break;
            
        case NSFetchedResultsChangeMove:
//            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
//            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void) pushObservations {
    NSLog(@"currently still pushing %lu observations", (unsigned long)self.pushingObservations.count);
//    if (self.pushingObservations.count != 0) return;
    
    // only push observations that haven't already been told to be pushed
    NSMutableDictionary *obsToPush = [[NSMutableDictionary alloc] init];
    for (Observation *observation in [self.fetchedResultsController fetchedObjects]) {
        if ([self.pushingObservations objectForKey:observation.objectID] == nil){
            [self.pushingObservations setObject:observation forKey:observation.objectID];
            [obsToPush setObject:observation forKey:observation.objectID];
        }
    }
    
    NSLog(@"about to push an additional %lu observations", (unsigned long)obsToPush.count);
    for (id observationId in obsToPush) {
        // let's pull the most up to date version of this observation to push
        NSManagedObjectContext *context = [NSManagedObjectContext defaultManagedObjectContext];
        NSError *error;
        Observation *observation = (Observation *)[context existingObjectWithID:observationId error:&error];
        if (observation == nil) {
            continue;
        }
        NSLog(@"submitting observation %@", observation.objectID);
        NSOperation *observationPushOperation = [Observation operationToPushObservation:observation success:^(id response) {
            NSLog(@"Successfully submitted observation");
            
            [observation populateObjectFromJson:response];
            observation.dirty = [NSNumber numberWithBool:NO];
            
            NSError *error;
            if (![[NSManagedObjectContext defaultManagedObjectContext] save:&error]) {
                NSLog(@"Error updating locations: %@", error);
            }
            
            [self.pushingObservations removeObjectForKey:observation.objectID];
        } failure:^{
            NSLog(@"Error submitting observation");
            [self.pushingObservations removeObjectForKey:observation.objectID];
        }];
        
        [[HttpManager singleton].manager.operationQueue addOperation:observationPushOperation];
    }
}

-(void) stop {
    if ([_observationPushTimer isValid]) {
        [_observationPushTimer invalidate];
        _observationPushTimer = nil;
        
    }
}

@end

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

NSString * const kObservationPushFrequencyKey = @"observationPushFrequency";

@interface ObservationPushService ()
@property (nonatomic) NSTimeInterval interval;
@property (nonatomic, strong) NSTimer* observationPushTimer;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@end

@implementation ObservationPushService

- (id) init {
    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        _interval = [[defaults valueForKey:kObservationPushFrequencyKey] doubleValue];
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:kObservationPushFrequencyKey
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
        
        NSManagedObjectContext *context = [NSManagedObjectContext defaultManagedObjectContext];
        
        // This needs to change to only pull dirty flag observations
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"Observation" inManagedObjectContext:context]];
        [fetchRequest setSortDescriptors:[NSArray arrayWithObjects:[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO], nil]];
        
        self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                   managedObjectContext:context
                                                                                                     sectionNameKeyPath:@"sectionName"
                                                                                                              cacheName:nil];
        
//        return [[Observations alloc] initWithFetchedResultsController:fetchedResultsController];
    }
    
    return self;
}

- (void) start {
    [self stop];
    
//    HttpManager *http = [HttpManager singleton];
//    NSOperation *layerPullOperation = [Layer operationToPullLayers:^(BOOL success) {
//        if (success) {
//            NSOperation* formPullOp = [Form operationToPullForm:^(BOOL success) {
//                if (success) {
//                    // Layers and Form pulled, lets start the observation fetch
//                    [self pullObservations];
//                } else {
//                    // TODO error
//                }
//            }];
//            
//            [http.manager.operationQueue addOperation:formPullOp];
//        } else {
//            // TODO error
//        }
//    }];
//    
//    [http.manager.operationQueue addOperation:layerPullOperation];
}

- (void) scheduleTimer {
    _observationPushTimer = [NSTimer timerWithTimeInterval:_interval target:self selector:@selector(onTimerFire) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:_observationPushTimer forMode:NSRunLoopCommonModes];
}

- (void) onTimerFire {
    [self pushObservations];
}

- (void) pushObservations {
//    NSOperation *observationFetchOperation = [Observation operationToPullObservations:^(BOOL success) {
//        [self scheduleTimer];
//    }];
//    
//    [[HttpManager singleton].manager.operationQueue addOperation:observationFetchOperation];
}

- (void) stop {
    if ([_observationPushTimer isValid]) {
        [_observationPushTimer invalidate];
        _observationPushTimer = nil;
    }
}

- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                        context:(void *)context {
    _interval = [[change objectForKey:NSKeyValueChangeNewKey] doubleValue];
    [self start];
}


@end

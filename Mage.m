//
//  Mage.m
//  mage-ios-sdk
//
//  Created by Dan Barela on 3/2/15.
//  Copyright (c) 2015 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "Mage.h"
#import "HttpManager.h"
#import "LocationService.h"
#import "LocationFetchService.h"
#import "ObservationFetchService.h"
#import "ObservationPushService.h"
#import "AttachmentPushService.h"
#import "User+helper.h"
#import "Event+helper.h"
#import "Form.h"
#import "Layer+helper.h"

@implementation Mage

+ (instancetype) singleton {
    static Mage *mage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mage = [[self alloc] init];
    });
    return mage;
}

- (id) init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eventsFetched:) name:MAGEEventsFetched object:nil];
    }
    
    return self;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) startServices {
    [[LocationService singleton] start];
    
    NSOperation *usersPullOp = [User operationToFetchUsers];
    NSOperation *startLocationFetchOp = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"done with intial user fetch, lets start the location fetch service");
        [[LocationFetchService singleton] start];
    }];
    
    NSOperation *startObservationFetchOp = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"done with intial user fetch, lets start the observation fetch service");
        [[ObservationFetchService singleton] start];
    }];
    
    [startObservationFetchOp addDependency:usersPullOp];
    [startLocationFetchOp addDependency:usersPullOp];
    
    [[ObservationPushService singleton] start];
    [[AttachmentPushService singleton] start];
    
    // Add the operations to the queue
    [[HttpManager singleton].manager.operationQueue addOperations:@[usersPullOp, startObservationFetchOp, startLocationFetchOp] waitUntilFinished:NO];
}

- (void) stopServices {
    [[LocationFetchService singleton] stop];
    [[ObservationFetchService singleton] stop];
    [[ObservationPushService singleton] stop];
    [[AttachmentPushService singleton] stop];
}

- (void) fetchEvents {
    NSOperation *myselfOp = [User operationToFetchMyselfWithCompletionBlock:^{
        [[HttpManager singleton].manager.operationQueue addOperation: [Event operationToFetchEvents]];
    }];
    [[HttpManager singleton].manager.operationQueue addOperation:myselfOp];
}

- (void) eventsFetched: (NSNotification *) notification {
    // after the events are fetched we need to go get the form icon zips
    NSArray *events = [Event MR_findAll];
    [self addFormFetchOperationsForEvents: events];
    [self addLayerFetchOperationsForEvents: events];
}

- (void) addFormFetchOperationsForEvents: (NSArray *) events {
    for (Event *e in events) {
        NSOperation *formOp = [Form operationToPullFormForEvent:e.remoteId
                                                        success: ^{
                                                            NSLog(@"Pulled form for event");
                                                        } failure:^{
                                                            NSLog(@"failed to pull form");
                                                        }];
        
        [[HttpManager singleton].manager.operationQueue addOperation:formOp];
    }
}

- (void) addLayerFetchOperationsForEvents: (NSArray *) events {
    for (Event *e in events) {
        NSOperation *formOp = [Layer operationToPullLayersForEvent:e.remoteId
                                                        success: ^{
                                                            NSLog(@"Pulled layers for event %@", e.remoteId);
                                                        } failure:^{
                                                            NSLog(@"Failed to pull layers for event %@", e.remoteId);
                                                        }];
        
        [[HttpManager singleton].manager.operationQueue addOperation:formOp];
    }
}

@end

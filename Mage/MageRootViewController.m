//
//  MageRootViewController.m
//  Mage
//
//  Created by Dan Barela on 4/28/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "MageRootViewController.h"
#import "MageNavigationController.h"
#import "MapViewController.h"
#import <HttpManager.h>

#import "User+helper.h"
#import <Observation+helper.h>

#import <Location+helper.h>
#import <Layer+helper.h>
#import <Form.h>

@implementation MageRootViewController

- (void) viewDidLoad {
    [self startServices];
	
	[super viewDidLoad];
}

- (void) startServices {
    [_locationServiceHolder.locationService start];
    
    NSOperation *usersPullOp = [User operationToFetchUsers];
    NSOperation *startLocationFetchOp = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"done with intial user fetch, lets start the location fetch service");
        [self.fetchServicesHolder.locationFetchService start];
    }];
    
    NSOperation *startObservationFetchOp = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"done with intial user fetch, lets start the observation fetch service");
        [self.fetchServicesHolder.observationFetchService start];
    }];
    
    [startObservationFetchOp addDependency:usersPullOp];
    [startLocationFetchOp addDependency:usersPullOp];
    
    [self.fetchServicesHolder.observationPushService start];
    
    // Add the operations to the queue
    [[HttpManager singleton].manager.operationQueue addOperations:@[usersPullOp, startObservationFetchOp, startLocationFetchOp] waitUntilFinished:NO];
}

@end

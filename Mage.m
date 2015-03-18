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
#import "MageServer.h"

@implementation Mage

+ (instancetype) singleton {
    static Mage *mage = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        mage = [[self alloc] init];
    });
    return mage;
}

- (void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void) startServices {
    [[LocationService singleton] start];
    
    NSOperation *usersPullOp = [User operationToFetchUsersWithSuccess:^{
        NSLog(@"Done with the initial user fetch, start location and observation services");
        [[LocationFetchService singleton] start];
        [[ObservationFetchService singleton] start];
    } failure:^(NSError *error) {
        
    }];
    
    [[ObservationPushService singleton] start];
    [[AttachmentPushService singleton] start];
    
    // Add the operations to the queue
    [[HttpManager singleton].manager.operationQueue addOperation:usersPullOp];
}

- (void) stopServices {
    [[LocationFetchService singleton] stop];
    [[ObservationFetchService singleton] stop];
    [[ObservationPushService singleton] stop];
    [[AttachmentPushService singleton] stop];
}

- (void) fetchEvents {
    NSOperation *myselfOp = [User operationToFetchMyselfWithSuccess:^{
        
        NSOperation *eventOp = [Event operationToFetchEventsWithSuccess:^{
            NSArray *events = [Event MR_findAll];
            [self addFormFetchOperationsForEvents: events];
        } failure:^(NSError *error) {
            NSLog(@"Failure to pull events");
            [[NSNotificationCenter defaultCenter] postNotificationName:MAGEEventsFetched object:nil];
        }];
        [[HttpManager singleton].manager.operationQueue addOperation: eventOp];
    } failure:^(NSError *error) {
        [[NSNotificationCenter defaultCenter] postNotificationName:MAGEEventsFetched object:nil];
    }];
    [[HttpManager singleton].manager.operationQueue addOperation:myselfOp];
}

- (void) addFormFetchOperationsForEvents: (NSArray *) events {
    for (Event *e in events) {
        NSOperation *formOp = [Form operationToPullFormForEvent:e.remoteId
                                                        success: ^{
                                                            NSLog(@"Pulled form for event");
                                                        } failure:^(NSError* error) {
                                                            NSLog(@"failed to pull form for event");
                                                        }];
        
        [[HttpManager singleton].manager.operationQueue addOperation:formOp];
    }
}

@end

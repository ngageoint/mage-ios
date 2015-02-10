//
//  LocationFetchService.m
//  mage-ios-sdk
//
//  Created by William Newman on 8/14/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "LocationFetchService.h"
#import "Location+helper.h"
#import "HttpManager.h"
#import "UserUtility.h"

NSString * const kLocationFetchFrequencyKey = @"userFetchFrequency";

@interface LocationFetchService ()
    @property (nonatomic) NSTimeInterval interval;
    @property (nonatomic, strong) NSTimer* locationFetchTimer;
@end

@implementation LocationFetchService

- (id) init {
    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        _interval = [[defaults valueForKey:kLocationFetchFrequencyKey] doubleValue];
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:kLocationFetchFrequencyKey
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
    }
	
	return self;
}

- (void) start {
    [self stop];

    [self pullLocations];
}

- (void) scheduleTimer {
    NSLog(@"told to schedule the timer");
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"in the main queue scheduling the timer");
        _locationFetchTimer = [NSTimer scheduledTimerWithTimeInterval:_interval target:self selector:@selector(onTimerFire) userInfo:nil repeats:NO];
    });
}

- (void) onTimerFire {
    NSLog(@"timer to pull locations fired");
    if (![[UserUtility singleton] isTokenExpired]) {
        [self pullLocations];
    }
}

- (void) pullLocations{
    NSOperation *locationFetchOperation = [Location operationToPullLocations:^(BOOL success) {
        if (![[UserUtility singleton] isTokenExpired]) {
            NSLog(@"Scheduling the timer again");
            [self scheduleTimer];
        }
    }];
    NSLog(@"pulling locations");
    [[HttpManager singleton].manager.operationQueue addOperation:locationFetchOperation];
}

-(void) stop {
    NSLog(@"told to stop the location timer");
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"if the timer is valid i am going to stop it");
        if ([_locationFetchTimer isValid]) {
            NSLog(@"Stopping the location timer");
            [_locationFetchTimer invalidate];
            _locationFetchTimer = nil;
        }
    });
}

- (void) observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    _interval = [[change objectForKey:NSKeyValueChangeNewKey] doubleValue];
    [self start];
}


@end

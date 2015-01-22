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
    dispatch_async(dispatch_get_main_queue(), ^{
        _locationFetchTimer = [NSTimer scheduledTimerWithTimeInterval:_interval target:self selector:@selector(onTimerFire) userInfo:nil repeats:NO];
    });
}

- (void) onTimerFire {
    [self pullLocations];
}

- (void) pullLocations{
    NSOperation *locationFetchOperation = [Location operationToPullLocations:^(BOOL success) {
        if (![UserUtility isTokenExpired]) {
            [self scheduleTimer];
        }
    }];
    
    [[HttpManager singleton].manager.operationQueue addOperation:locationFetchOperation];
}

-(void) stop {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_locationFetchTimer isValid]) {
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

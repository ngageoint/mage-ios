//
//  LocationFetchService.m
//  mage-ios-sdk
//
//

#import "LocationFetchService.h"
#import "MageSessionManager.h"
#import "DataConnectionUtilities.h"
#import "MAGE-Swift.h"

NSString * const kLocationFetchFrequencyKey = @"userFetchFrequency";

@interface LocationFetchService ()
    @property (nonatomic) NSTimeInterval interval;
    @property (nonatomic, strong) NSTimer* locationFetchTimer;
@end

@implementation LocationFetchService

+ (instancetype) singleton {
    static LocationFetchService *fetchService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fetchService = [[self alloc] init];
    });
    return fetchService;
}

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
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.locationFetchTimer = [NSTimer scheduledTimerWithTimeInterval:weakSelf.interval target:weakSelf selector:@selector(onTimerFire) userInfo:nil repeats:NO];
    });
}

- (void) onTimerFire {
    NSLog(@"timer to pull locations fired");
    if (![[UserUtility singleton] isTokenExpired]) {
        [self pullLocations];
    }
}

- (void) pullLocations{
    if ([DataConnectionUtilities shouldFetchLocations]) {
        NSURLSessionDataTask *locationFetchTask = [Location operationToPullLocationsWithSuccess:^(NSURLSessionDataTask * _Nonnull task, id _Nullable response) {
            if (![[UserUtility singleton] isTokenExpired]) {
                NSLog(@"Scheduling the location fetch timer");
                [self scheduleTimer];
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"Failed to pull locations, scheduling the timer again");
            [self scheduleTimer];
        }];
        
        NSLog(@"pulling locations");
        [[MageSessionManager sharedManager] addTask:locationFetchTask];
    } else {
        [self scheduleTimer];
    }
}

-(void) stop {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([weakSelf.locationFetchTimer isValid]) {
            NSLog(@"Stopping the location fetch timer");
            [weakSelf.locationFetchTimer invalidate];
            weakSelf.locationFetchTimer = nil;
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

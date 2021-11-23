//
//  ObservationFetchService.m
//  mage-ios-sdk
//
//

#import "ObservationFetchService.h"
#import "MAGE-Swift.h"
#import "MageSessionManager.h"
#import "DataConnectionUtilities.h"

NSString * const kObservationFetchFrequencyKey = @"observationFetchFrequency";

@interface ObservationFetchService ()
    @property (nonatomic) NSTimeInterval interval;
    @property (nonatomic, strong) NSTimer* observationFetchTimer;
@end

@implementation ObservationFetchService

+ (instancetype) singleton {
    static ObservationFetchService *fetchService = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        fetchService = [[self alloc] init];
        fetchService.started = false;
    });
    return fetchService;
}

- (id) init {
    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        _interval = [[defaults valueForKey:kObservationFetchFrequencyKey] doubleValue];
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:kObservationFetchFrequencyKey
                                                   options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld
                                                   context:NULL];
    }
	
	return self;
}

- (void) startAsInitial:(BOOL)initial {
    [self stop];
    if (initial) {
        [self pullInitialObservations];
    } else {
        [self pullObservations];
    }
    self.started = true;
}

- (void) scheduleTimer {
    if (self.observationFetchTimer != nil) {
        if ([self.observationFetchTimer isValid]) {
            [self.observationFetchTimer invalidate];
            self.observationFetchTimer = nil;
        }
    }
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.observationFetchTimer = [NSTimer scheduledTimerWithTimeInterval:weakSelf.interval target:weakSelf selector:@selector(onTimerFire:) userInfo:nil repeats:NO];
    });
}

- (void) onTimerFire: (NSTimer *) timer {
    if (![[UserUtility singleton] isTokenExpired]) {
        [self pullObservations];
    }
}

- (void) pullInitialObservations {
    if ([DataConnectionUtilities shouldFetchObservations]) {
        NSURLSessionDataTask *observationFetchTask = [Observation operationToPullInitialObservationsWithSuccess:^(NSURLSessionDataTask * _Nonnull task , id _Nullable response) {
            if (![[UserUtility singleton] isTokenExpired]) {
                [self scheduleTimer];
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (![[UserUtility singleton] isTokenExpired]) {
                [self scheduleTimer];
            }
        }];
        
        [[MageSessionManager sharedManager] addTask:observationFetchTask];
    } else {
        [self scheduleTimer];
    }
}

- (void) pullObservations {
    if ([DataConnectionUtilities shouldFetchObservations]) {
        NSURLSessionDataTask *observationFetchTask = [Observation operationToPullObservationsWithSuccess:^(NSURLSessionDataTask * _Nonnull task , id _Nullable response){
            if (![[UserUtility singleton] isTokenExpired]) {
                [self scheduleTimer];
            }
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (![[UserUtility singleton] isTokenExpired]) {
                [self scheduleTimer];
            }
        }];
        if (observationFetchTask != nil) {
            [[MageSessionManager sharedManager] addTask:observationFetchTask];
        }
    } else {
        [self scheduleTimer];
    }
}

- (void) stop {
    self.started = false;
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // TODO: if this gets run after the timer is schedule in start, it will stop fetching
        if ([weakSelf.observationFetchTimer isValid]) {
            [weakSelf.observationFetchTimer invalidate];
            weakSelf.observationFetchTimer = nil;
        }
    });
}

- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                        context:(void *)context {
    if ([[change objectForKey:NSKeyValueChangeNewKey] doubleValue] == _interval) {
        // we were called but the value is the same, ignore it
        return;
    }
    _interval = [[change objectForKey:NSKeyValueChangeNewKey] doubleValue];
    if (_started) {
        [self startAsInitial:NO];
    }
}

@end

//
//  ObservationFetchService.m
//  mage-ios-sdk
//
//

#import "ObservationFetchService.h"
#import "Observation.h"
#import "Layer.h"
#import "Form.h"
#import "MageSessionManager.h"
#import "UserUtility.h"
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
    });
    return fetchService;
}

- (id) init {
    if (self = [super init]) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        _interval = [[defaults valueForKey:kObservationFetchFrequencyKey] doubleValue];
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:kObservationFetchFrequencyKey
                                                   options:NSKeyValueObservingOptionNew
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
}

- (void) scheduleTimer {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.observationFetchTimer = [NSTimer scheduledTimerWithTimeInterval:_interval target:weakSelf selector:@selector(onTimerFire) userInfo:nil repeats:NO];
    });
}

- (void) onTimerFire {
    if (![[UserUtility singleton] isTokenExpired]) {
        [self pullObservations];
    }
}

- (void) pullInitialObservations {
    if ([DataConnectionUtilities shouldFetchObservations]) {
        NSURLSessionDataTask *observationFetchTask = [Observation operationToPullInitialObservationsWithSuccess:^{
            if (![[UserUtility singleton] isTokenExpired]) {
                [self scheduleTimer];
            }
        } failure:^(NSError* error) {
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
        NSURLSessionDataTask *observationFetchTask = [Observation operationToPullObservationsWithSuccess:^{
            if (![[UserUtility singleton] isTokenExpired]) {
                [self scheduleTimer];
            }
        } failure:^(NSError* error) {
            if (![[UserUtility singleton] isTokenExpired]) {
                [self scheduleTimer];
            }
        }];
        
        [[MageSessionManager sharedManager] addTask:observationFetchTask];
    } else {
        [self scheduleTimer];
    }
}

- (void) stop {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
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
    _interval = [[change objectForKey:NSKeyValueChangeNewKey] doubleValue];
    [self startAsInitial:NO];
}

@end

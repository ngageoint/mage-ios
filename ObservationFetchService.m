//
//  ObservationFetchService.m
//  mage-ios-sdk
//
//

#import "ObservationFetchService.h"
#import "Observation.h"
#import "Layer.h"
#import "Form.h"
#import "HttpManager.h"
#import "UserUtility.h"

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

- (void) start {
    [self stop];
    [self pullObservations];    
}

- (void) scheduleTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        _observationFetchTimer = [NSTimer scheduledTimerWithTimeInterval:_interval target:self selector:@selector(onTimerFire) userInfo:nil repeats:NO];
    });
}

- (void) onTimerFire {
    if (![[UserUtility singleton] isTokenExpired]) {
        [self pullObservations];
    }
}

- (void) pullObservations {
    NSOperation *observationFetchOperation = [Observation operationToPullObservationsWithSuccess:^{
        if (![[UserUtility singleton] isTokenExpired]) {
            [self scheduleTimer];
        }
    } failure:^(NSError* error) {
        if (![[UserUtility singleton] isTokenExpired]) {
            [self scheduleTimer];
        }
    }];
    
    [[HttpManager singleton].manager.operationQueue addOperation:observationFetchOperation];
}

- (void) stop {
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_observationFetchTimer isValid]) {
            [_observationFetchTimer invalidate];
            _observationFetchTimer = nil;
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

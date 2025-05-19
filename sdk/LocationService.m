//
//  LocationService.m
//  mage-ios-sdk
//
//

#import "LocationService.h"
#import "MageSessionManager.h"
#import "MAGE-Swift.h"
#import "CoreDataManager.h"

NSString * const kReportLocationKey = @"reportLocation";
NSString * const kGPSDistanceFilterKey = @"gpsDistanceFilter";
NSString * const kLocationReportingFrequencyKey = @"userReportingFrequency";

NSInteger const kLocationPushLimit = 100;

@interface LocationService ()
    @property (nonatomic) BOOL isPushingLocations;
    @property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
    @property (nonatomic, strong) CLLocationManager *locationManager;
    @property (nonatomic, strong) NSDate *oldestLocationTime;
    @property (nonatomic) NSTimeInterval locationPushInterval;
    @property (nonatomic) BOOL reportLocation;
@property (nonatomic, strong) NSManagedObjectContext* context;
@end

@implementation LocationService

+ (instancetype) singleton {
    static LocationService *service = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[self alloc] init];
        service.started = false;
    });
    return service;
}

- (id) init {
    if (self = [super init]) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _reportLocation = [defaults boolForKey:kReportLocationKey];
        _locationPushInterval = [[defaults objectForKey:kLocationReportingFrequencyKey] doubleValue];
        
        // for now filter and accuracy are based on the same preference
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.pausesLocationUpdatesAutomatically = NO;
        _locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
        _locationManager.distanceFilter = [[defaults objectForKey:kGPSDistanceFilterKey] doubleValue];
        _locationManager.delegate = self;
        
        // Check for iOS 8
        if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
            [_locationManager requestWhenInUseAuthorization];
        }
        
        if ([_locationManager respondsToSelector:@selector(allowsBackgroundLocationUpdates)]) {
            [_locationManager setAllowsBackgroundLocationUpdates:YES];
        }
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:kLocationReportingFrequencyKey
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:kGPSDistanceFilterKey
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:kReportLocationKey
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
	}
	
	return self;
}

- (void) start: (NSManagedObjectContext *) context {
    self.context = context;
    if (_reportLocation) {
        [self.locationManager startUpdatingLocation];
    }
    [self pushLocations];
    self.started = true;
}

- (void) stop {
    [self.locationManager stopUpdatingLocation];
    
    [self pushLocations];
    self.started = false;
}

- (void) locationManager:(CLLocationManager *) manager didUpdateLocations:(NSArray *) locations {
    if (!_reportLocation || [[NSUserDefaults standardUserDefaults] locationServiceDisabled]) return;
    
    __block NSTimeInterval interval;
    __weak typeof(self) weakSelf = self;

    [[CoreDataManager sharedManager] saveContext:^(NSManagedObjectContext *localContext) {
        if ([[Event getCurrentEventWithContext:localContext] isUserInEventWithUser:[User fetchCurrentUserWithContext:localContext]]) {
            NSMutableArray *locationEntities = [NSMutableArray arrayWithCapacity:locations.count];
            for (CLLocation *location in locations) {
                [locationEntities addObject:[GPSLocation gpsLocationWithLocation:location context:localContext]];
            }
            
            CLLocation *location = [locations firstObject];
            interval = [[location timestamp] timeIntervalSinceDate:weakSelf.oldestLocationTime];
            if (weakSelf.oldestLocationTime == nil) {
                weakSelf.oldestLocationTime = [location timestamp];
            }
        }
    } completion:^(BOOL contextDidSave, NSError *error) {
        if (interval > weakSelf.locationPushInterval) {
            [weakSelf pushLocations];
            weakSelf.oldestLocationTime = nil;
        }
    }];
}

- (void) pushLocations {
    if (!self.isPushingLocations && [DataConnectionUtilities shouldPushLocations]) {
        
        //TODO, submit in pages
        NSFetchRequest *fetchRequest = [GPSLocation fetchRequest];
        fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K = %@", @"eventId", [Server currentEventId]];
        [fetchRequest setFetchLimit:kLocationPushLimit];
        [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
        NSError *error = nil;
        NSArray *locations = [_context executeFetchRequest:fetchRequest error:&error];
        //[GPSLocation MR_executeFetchRequest:fetchRequest inContext:self.context];
        
        if (![locations count]) return;
        
        self.isPushingLocations = YES;
        NSLog(@"Pushing locations...");
        
        // send to server
        __weak LocationService *weakSelf = self;
        
        
        NSURLSessionDataTask *locationTask = [GPSLocation operationToPushWithLocations:locations success:^(NSURLSessionDataTask * _Nullable task, id _Nullable response) {
            [self->_context performBlockAndWait:^{
                for (GPSLocation *location in locations) {
                    [weakSelf.context deleteObject:location];
                }
                NSError *error = nil;
                [weakSelf.context save:&error];
            }];
            self.isPushingLocations = NO;
            
            if ([locations count] == kLocationPushLimit) {
                [weakSelf pushLocations];
            }
        } failure:^(NSError * _Nonnull error) {
            NSLog(@"Failure to push GPS locations to the server");
            self.isPushingLocations = NO;
        }];
        
        [[MageSessionManager sharedManager] addTask:locationTask];
    }
}

- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                        context:(void *)context {
    if ([kGPSDistanceFilterKey isEqualToString:keyPath]) {
        double gpsSensitivity = [[change objectForKey:NSKeyValueChangeNewKey] doubleValue];
        [_locationManager setDistanceFilter:gpsSensitivity];
    } else if ([kLocationReportingFrequencyKey isEqualToString:keyPath]) {
        _locationPushInterval = [[change objectForKey:NSKeyValueChangeNewKey] doubleValue];
    } else if ([kReportLocationKey isEqualToString:keyPath]) {
        _reportLocation = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        _reportLocation ? [self start:self.context] : [self stop];
    }
}

- (CLLocation *) location {
    return [self.locationManager location];
}

@end

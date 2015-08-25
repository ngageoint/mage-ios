//
//  LocationService.m
//  mage-ios-sdk
//
//  Created by William Newman on 8/18/14.
//  Copyright (c) 2014 National Geospatial-Intelligence Agency. All rights reserved.
//

#import "LocationService.h"
#import "User+helper.h"
#import "GPSLocation+helper.h"
#import "GeoPoint.h"
#import "Event+helper.h"
#import "Server+helper.h"
#import "HttpManager.h"

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
    @property (nonatomic, strong) NSOperationQueue *operationQueue;
    @property (nonatomic) BOOL reportLocation;
@end

@implementation LocationService

+ (instancetype) singleton {
    static LocationService *service = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        service = [[self alloc] init];
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
        
        _operationQueue = [[NSOperationQueue alloc] init];
        [_operationQueue setName:@"Location Push Operation Queue"];
        [_operationQueue setMaxConcurrentOperationCount:1];
        
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

- (void) start {
    [self.locationManager startUpdatingLocation];
    [self pushLocations];
}

- (void) stop {
    [self.locationManager stopUpdatingLocation];
    
    [self pushLocations];
}

//[MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {

- (void) locationManager:(CLLocationManager *) manager didUpdateLocations:(NSArray *) locations {
    if (!_reportLocation) return;
    
    __block NSTimeInterval interval;
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        if ([[Event getCurrentEvent] isUserInEvent:[User fetchCurrentUserInManagedObjectContext:localContext]]) {
            NSMutableArray *locationEntities = [NSMutableArray arrayWithCapacity:locations.count];
            for (CLLocation *location in locations) {
                [locationEntities addObject:[GPSLocation gpsLocationForLocation:location inManagedObjectContext:localContext]];
            }
            
            CLLocation *location = [locations firstObject];
            interval = [[location timestamp] timeIntervalSinceDate:_oldestLocationTime];
            if (self.oldestLocationTime == nil) {
                self.oldestLocationTime = [location timestamp];
            }
        }
    } completion:^(BOOL contextDidSave, NSError *error) {
        if (interval > self.locationPushInterval) {
            [self pushLocations];
            self.oldestLocationTime = nil;
        }
    }];
}

- (void) pushLocations {
    if (!self.isPushingLocations) {
        
        //TODO, submit in pages
        NSFetchRequest *fetchRequest = [GPSLocation MR_requestAllWhere:@"eventId" isEqualTo:[Server currentEventId] inContext:[NSManagedObjectContext MR_defaultContext]];
        [fetchRequest setFetchLimit:kLocationPushLimit];
        [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"timestamp" ascending:NO]]];
        NSArray *locations = [GPSLocation MR_executeFetchRequest:fetchRequest inContext:[NSManagedObjectContext MR_context]];
        
        if (![locations count]) return;
        
        self.isPushingLocations = YES;
        NSLog(@"Pushing locations...");
        
        // send to server
        __weak LocationService *weakSelf = self;
        NSOperation *locationPushOperation = [GPSLocation operationToPushGPSLocations:locations success:^{
            for (GPSLocation *location in locations) {
                [location MR_deleteEntityInContext:[NSManagedObjectContext MR_context]];
            }
            
            [weakSelf.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *error) {
                self.isPushingLocations = NO;
                
                if ([locations count] == kLocationPushLimit) [weakSelf pushLocations];
            }];
        } failure:^(NSError* failure) {
            NSLog(@"Failure to push GPS locations to the server");
            self.isPushingLocations = NO;
        }];
        
        [[HttpManager singleton].manager.operationQueue addOperation:locationPushOperation];
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
        _reportLocation ? [self start] : [self stop];
    }
}

- (CLLocation *) location {
    return [self.locationManager location];
}

@end

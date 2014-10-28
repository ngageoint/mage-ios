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
#import "NSManagedObjectContext+MAGE.h"

NSString * const kReportLocationKey = @"reportLocation";
NSString * const kGPSSensitivityKey = @"gpsSensitivity";
NSString * const kLocationReportingFrequencyKey = @"userReportingFrequency";

@interface LocationService ()
    @property (nonatomic, strong) CLLocationManager *locationManager;
    @property (nonatomic, strong) NSDate *oldestLocationTime;
    @property (nonatomic) NSTimeInterval locationPushInterval;
    @property (nonatomic, strong) NSOperationQueue *operationQueue;
    @property (nonatomic) BOOL reportLocation;
@end

@implementation LocationService

- (id) init {
    if (self = [super init]) {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        _reportLocation = [defaults boolForKey:kReportLocationKey];
        _locationPushInterval = [[defaults objectForKey:kLocationReportingFrequencyKey] doubleValue];
        
        // for now filter and accuracy are based on the same preference
        double gpsSensitivity = [[defaults objectForKey:kGPSSensitivityKey] doubleValue];
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.desiredAccuracy = gpsSensitivity;
        _locationManager.distanceFilter = gpsSensitivity;
        _locationManager.delegate = self;
        
        // Check for iOS 8
        if ([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [_locationManager requestAlwaysAuthorization];
        }
        
        NSArray *locations = [GPSLocation fetchGPSLocations];
        GPSLocation *location = [locations firstObject];
        _oldestLocationTime = location.timestamp;
        
        _operationQueue = [[NSOperationQueue alloc] init];
        [_operationQueue setName:@"Location Push Operation Queue"];
        [_operationQueue setMaxConcurrentOperationCount:1];
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:kLocationReportingFrequencyKey
                                                   options:NSKeyValueObservingOptionNew
                                                   context:NULL];
        
        [[NSUserDefaults standardUserDefaults] addObserver:self
                                                forKeyPath:kGPSSensitivityKey
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
    if (_reportLocation) {
        [self.locationManager startUpdatingLocation];
    }
}

- (void) stop {
    [self.locationManager stopUpdatingLocation];
}

- (void) locationManager:(CLLocationManager *) manager didUpdateLocations:(NSArray *) locations {
    NSLog(@"got a new location");
    [self persistLocations:locations];
    
    CLLocation *location = [locations firstObject];
    NSTimeInterval interval = [[location timestamp] timeIntervalSinceDate:_oldestLocationTime];
    if (self.oldestLocationTime == nil) {
        self.oldestLocationTime = [location timestamp];
    }
    
    if (interval > _locationPushInterval) {
        [self pushLocations];
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    NSLog(@"Error updating location %@", error);
}


- (NSArray *) persistLocations:(NSArray *) locations {
    NSMutableArray *locationEntities = [NSMutableArray arrayWithCapacity:locations.count];
    for (CLLocation *location in locations) {
        [locationEntities addObject:[GPSLocation gpsLocationForLocation:location]];
    }
    
    NSError *error = nil;
    if (! [[NSManagedObjectContext defaultManagedObjectContext] save:&error]) {
        NSLog(@"Error updating locations: %@", error);
    }
    
    return locationEntities;
}

- (void) pushLocations {
    if ([self.operationQueue operationCount] == 0) {
        NSLog(@"Pushing locations...");
        
        //TODO, submit in pages
        NSArray *locations = [GPSLocation fetchGPSLocations];
        
        // send to server
        NSOperation *locationPushOperation = [GPSLocation operationToPushGPSLocations:locations success:^{
            self.oldestLocationTime = nil;
            for (GPSLocation *location in locations) {
                [[NSManagedObjectContext defaultManagedObjectContext] deleteObject:location];
            }
        } failure:^{
            NSLog(@"Failure to push GPS locations to the server");
        }];
        
        [self.operationQueue addOperation:locationPushOperation];
    }
}

- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                        context:(void *)context {
    if ([kGPSSensitivityKey isEqualToString:keyPath]) {
        double gpsSensitivity = [[change objectForKey:NSKeyValueChangeNewKey] doubleValue];
        [_locationManager setDesiredAccuracy:gpsSensitivity];
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

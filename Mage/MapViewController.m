//
//  MapViewController.m
//  Mage
//
//  Created by Dan Barela on 4/29/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "MapViewController.h"

#import "AppDelegate.h"
#import "Geometry.h"
#import "GeoPoint.h"
#import "PersonImage.h"
#import "User+helper.h"
#import "Location+helper.h"
#import "LocationAnnotation.h"
#import "LocationService.h"
#import "ObservationAnnotation.h"
#import "Observation.h"
#import "ObservationImage.h"
#import "PersonViewController.h"
#import "ObservationViewController.h"
#import <MapKit/MapKit.h>
#import "MapFetchedResultsDelegate.h"
#import "MapDelegate.h"
#import "LocationFetchedResultsController.h"
#import "ObservationFetchedResultsController.h"
#import "MageRootViewController.h"

@interface MapViewController ()
    @property (nonatomic) IBOutlet MapFetchedResultsDelegate *mapFetchedResultsDelegate;
    @property (nonatomic) IBOutlet MapDelegate *mapDelegate;
    @property (strong, nonatomic) LocationFetchedResultsController *locationResultsController;
    @property (strong, nonatomic) ObservationFetchedResultsController *observationResultsController;
@end

@implementation MapViewController

- (NSFetchedResultsController *) observationResultsController {
    
    if (_observationResultsController != nil) {
		return _observationResultsController;
	}
    _observationResultsController = [[ObservationFetchedResultsController alloc] initWithManagedObjectContext:_managedObjectContext];
    [_observationResultsController setDelegate:self.mapFetchedResultsDelegate];
    return _observationResultsController;
}

- (NSFetchedResultsController *) locationResultsController {
    if (_locationResultsController != nil) {
		return _locationResultsController;
	}
    _locationResultsController = [[LocationFetchedResultsController alloc] initWithManagedObjectContext:_managedObjectContext];
    [_locationResultsController setDelegate:self.mapFetchedResultsDelegate];
    return _locationResultsController;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:kReportLocationKey]) {
        [_mapView setShowsUserLocation:YES];
        [_mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    } else {
        [_mapView setShowsUserLocation:NO];
        [_mapView setUserTrackingMode:MKUserTrackingModeNone animated:YES];
    }
    
    NSError *error;
    if (![[self locationResultsController] performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
	
	NSArray *locations = [self.locationResultsController fetchedObjects];
	[self.mapFetchedResultsDelegate updateLocations:locations];
    
    if (![[self observationResultsController] performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail/Users/wnewman/Downloads/ios_development (1).cer
    }
	
	NSArray *observations = [self.observationResultsController fetchedObjects];
    NSLog(@"we initially found %lu observations", (unsigned long)observations.count);
	[self.mapFetchedResultsDelegate updateObservations:observations];
}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    if ([segue.identifier isEqualToString:@"DisplayPersonSegue"]) {
		User *user = nil;
		if ([sender annotation] == _mapView.userLocation) {
			user = [User fetchCurrentUserForManagedObjectContext:_managedObjectContext];
		} else {
			LocationAnnotation *annotation = [sender annotation];
			user = annotation.location.user;
		}
		
		PersonViewController *destinationViewController = segue.destinationViewController;
		[destinationViewController setUser:user];
		[destinationViewController setManagedObjectContext:_managedObjectContext];

    } else if ([segue.identifier isEqualToString:@"DisplayObservationSegue"]) {
		ObservationAnnotation *annotation = [sender annotation];
		
		ObservationViewController *destinationViewController = segue.destinationViewController;
		[destinationViewController setObservation:annotation.observation];
    }
}

@end

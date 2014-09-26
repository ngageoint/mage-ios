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
#import "LocationFetchedResultsController.h"
#import "ObservationFetchedResultsController.h"
#import "MageRootViewController.h"

@interface MapViewController ()
    @property (strong, nonatomic) LocationFetchedResultsController *locationResultsController;
    @property (strong, nonatomic) ObservationFetchedResultsController *observationResultsController;
@end

@implementation MapViewController

- (NSFetchedResultsController *) observationResultsController {
    
    if (_observationResultsController != nil) {
		return _observationResultsController;
	}
    _observationResultsController = [[ObservationFetchedResultsController alloc] initWithManagedObjectContext:self.contextHolder.managedObjectContext];
    [_observationResultsController setDelegate:self.mapDelegate];
    return _observationResultsController;
}

- (NSFetchedResultsController *) locationResultsController {
    if (_locationResultsController != nil) {
		return _locationResultsController;
	}
    _locationResultsController = [[LocationFetchedResultsController alloc] initWithManagedObjectContext:self.contextHolder.managedObjectContext];
    [_locationResultsController setDelegate:self.mapDelegate];
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
        exit(-1);
    }
	
	NSArray *locations = [self.locationResultsController fetchedObjects];
	[self.mapDelegate updateLocations:locations];
    
    if (![[self observationResultsController] performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);
    }
	
	NSArray *observations = [self.observationResultsController fetchedObjects];
    NSLog(@"we initially found %lu observations", (unsigned long)observations.count);
	[self.mapDelegate updateObservations:observations];
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
		PersonViewController *destinationViewController = segue.destinationViewController;
		[destinationViewController setUser:sender];
    } else if ([segue.identifier isEqualToString:@"DisplayObservationSegue"]) {
		ObservationViewController *destinationViewController = segue.destinationViewController;
		[destinationViewController setObservation:sender];
    }
}

@end

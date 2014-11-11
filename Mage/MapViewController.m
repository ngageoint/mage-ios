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
#import "MeViewController.h"
#import "ObservationViewController.h"
#import <MapKit/MapKit.h>
#import "Locations.h"
#import "Observations.h"
#import "MageRootViewController.h"
#import "MapDelegate.h"
#import "ObservationEditViewController.h"

@interface MapViewController ()
    @property (strong, nonatomic) Observations *observationResultsController;
@end

@implementation MapViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    Locations *locations = [Locations locationsForAllUsers];
    [self.mapDelegate setLocations:locations];
    
    Observations *observations = [Observations observations];
    [self.mapDelegate setObservations:observations];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:kReportLocationKey]) {
        [_mapView setShowsUserLocation:YES];
        [_mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
    } else {
        [_mapView setShowsUserLocation:NO];
        [_mapView setUserTrackingMode:MKUserTrackingModeNone animated:YES];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    if ([segue.identifier isEqualToString:@"DisplayPersonSegue"]) {
		MeViewController *destinationViewController = segue.destinationViewController;
		[destinationViewController setUser:sender];
    } else if ([segue.identifier isEqualToString:@"DisplayObservationSegue"]) {
		ObservationViewController *destinationViewController = segue.destinationViewController;
		[destinationViewController setObservation:sender];
    } else if ([segue.identifier isEqualToString:@"CreateNewObservationSegue"]) {
        ObservationEditViewController *editViewController = segue.destinationViewController;
        
        CLLocation *location = [[CLLocation alloc] initWithLatitude:[self.mapView centerCoordinate].latitude longitude:[self.mapView centerCoordinate].longitude];
        GeoPoint *point = [[GeoPoint alloc] initWithLocation:location];
        
        [editViewController setLocation:point];
    }
}

@end

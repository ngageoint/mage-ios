//
//  MapViewController_iPad.m
//  MAGE
//
//  Created by William Newman on 9/30/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MapViewController_iPad.h"
#import "ObservationEditViewController.h"
#import <GeoPoint.h>
#import "LocationAnnotation.h"
#import "ObservationAnnotation.h"
#import <Location+helper.h>

@implementation MapViewController_iPad

- (void) viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:YES];
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO];
    [super viewWillDisappear:animated];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"CreateNewObservationSegue"]) {
        ObservationEditViewController *editViewController = segue.destinationViewController;
        
        CLLocation *location = [[CLLocation alloc] initWithLatitude:[self.mapView centerCoordinate].latitude longitude:[self.mapView centerCoordinate].longitude];
        GeoPoint *point = [[GeoPoint alloc] initWithLocation:location];
        
        [editViewController setLocation:point];
    } else {
        [super prepareForSegue:segue sender:sender];
    }
}

-(void) calloutTapped:(id) calloutItem {
    if ([calloutItem isKindOfClass:[User class]]) {
        [self userDetailSelected:(User *)calloutItem];
    } else if ([calloutItem isKindOfClass:[Observation class]]) {
        [self observationDetailSelected:(Observation *) calloutItem];
    }
}


- (void)selectedUser:(User *) user {
    [self.mapDelegate selectedUser:user];
}

- (void)selectedUser:(User *) user region:(MKCoordinateRegion) region {
    [self.mapDelegate selectedUser:user region:region];
}

- (void)selectedObservation:(Observation *) observation {
    [self.mapDelegate selectedObservation:observation];
}

- (void)selectedObservation:(Observation *) observation region:(MKCoordinateRegion) region {
    [self.mapDelegate selectedObservation:observation region:region];
}

- (void)observationDetailSelected:(Observation *)observation {
    [self.mapDelegate observationDetailSelected:observation];
    [self performSegueWithIdentifier:@"DisplayObservationSegue" sender:observation];
}

- (void)userDetailSelected:(User *)user {
    [self.mapDelegate userDetailSelected:user];
    [self performSegueWithIdentifier:@"DisplayPersonSegue" sender:user];
}

@end

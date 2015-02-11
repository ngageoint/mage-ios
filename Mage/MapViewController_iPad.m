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
    LocationAnnotation *annotation = [self.mapDelegate.locationAnnotations objectForKey:user.remoteId];
    [self.mapView selectAnnotation:annotation animated:YES];
    
    [self.mapView setCenterCoordinate:[annotation.location location].coordinate];
}

- (void)selectedUser:(User *) user region:(MKCoordinateRegion) region {
    LocationAnnotation *annotation = [self.mapDelegate.locationAnnotations objectForKey:user.remoteId];
    
    [self.mapView setRegion:region animated:YES];
    [self.mapView selectAnnotation:annotation animated:YES];
}

- (void)selectedObservation:(Observation *) observation {
    [self.mapView setCenterCoordinate:[observation location].coordinate];
    
    ObservationAnnotation *annotation = [self.mapDelegate.observationAnnotations objectForKey:observation.objectID];
    [self.mapView selectAnnotation:annotation animated:YES];
}

- (void)selectedObservation:(Observation *) observation region:(MKCoordinateRegion) region {
    LocationAnnotation *annotation = [self.mapDelegate.observationAnnotations objectForKey:observation.remoteId];
    
    [self.mapView setRegion:region animated:YES];
    [self.mapView selectAnnotation:annotation animated:YES];
}

- (void)observationDetailSelected:(Observation *)observation {
    [self selectedObservation:observation];
    [self performSegueWithIdentifier:@"DisplayObservationSegue" sender:observation];
}

- (void)userDetailSelected:(User *)user {
    [self selectedUser:user];
    [self performSegueWithIdentifier:@"DisplayPersonSegue" sender:user];
}

//- (void)splitViewController:(UISplitViewController *)svc
//    willChangeToDisplayMode:(UISplitViewControllerDisplayMode)displayMode {
//    
//    // never called in ios 7
//    self.masterViewButton = svc.displayModeButtonItem;
//    if (displayMode == UISplitViewControllerDisplayModePrimaryOverlay) {
//        [self ensureButtonVisible];
//    } else if (displayMode == UISplitViewControllerDisplayModePrimaryHidden) {
//        [self ensureButtonVisible];
//    } else if (displayMode == UISplitViewControllerDisplayModeAllVisible) {
//        NSMutableArray *items = [self.mapViewController.toolbar.items mutableCopy];
//        [items removeObject:self.masterViewButton];
//        [self.mapViewController.toolbar setItems:items];
//        
//        self.masterViewButton = nil;
//        self.masterViewPopover = nil;
//    }
//    [self.mapViewController splitViewController:svc willChangeToDisplayMode:displayMode];
//}
//
//-(void)splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *) button {
//    NSLog(@"will show view controller");
//    // never called in ios 8
//    self.masterViewButton = nil;
//    self.masterViewPopover = nil;
//    
//    NSMutableArray *items = [self.mapViewController.toolbar.items mutableCopy];
//    [items removeObject:button];
//    [self.mapViewController.toolbar setItems:items];
//    [self.mapViewController splitViewController:svc willShowViewController:aViewController invalidatingBarButtonItem:button];
//}
//
//
//-(void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)button forPopoverController:(UIPopoverController *) pc {
//    NSLog(@"will hide view controller");
//    self.masterViewButton = button;
//    self.masterViewPopover = pc;
//    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
//        return;
//    }
//    
//    // always called in both ios8 and 7
//    [self ensureButtonVisible];
//    [self.mapViewController splitViewController:svc willHideViewController:aViewController withBarButtonItem:button forPopoverController:pc];
//}



@end

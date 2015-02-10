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
#import "LocationAnnotation.h"
#import "ObservationAnnotation.h"

@interface MapViewController ()<UserTrackingModeChanged>
    @property (weak, nonatomic) IBOutlet UIButton *trackingButton;
    @property (weak, nonatomic) IBOutlet UIButton *reportLocationButton;
    @property (weak, nonatomic) IBOutlet UIView *toastView;
    @property (weak, nonatomic) IBOutlet UILabel *toastText;

    @property (strong, nonatomic) Observations *observationResultsController;
    @property (strong, nonatomic) CLLocation *mapPressLocation;
@end

@implementation MapViewController

- (IBAction)mapLongPress:(id)sender {
    UIGestureRecognizer *gestureRecognizer = (UIGestureRecognizer *)sender;
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
        CLLocationCoordinate2D touchMapCoordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
        self.mapPressLocation = [[CLLocation alloc] initWithLatitude:touchMapCoordinate.latitude longitude:touchMapCoordinate.longitude];
        [self performSegueWithIdentifier:@"CreateNewObservationAtPointSegue" sender:sender];
    }
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    Locations *locations = [Locations locationsForAllUsers];
    [self.mapDelegate setLocations:locations];
    
    Observations *observations = [Observations observations];
    [self.mapDelegate setObservations:observations];
    
    self.mapDelegate.userTrackingModeDelegate = self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.mapDelegate.hideLocations = [defaults boolForKey:@"hidePeople"];
    self.mapDelegate.hideObservations = [defaults boolForKey:@"hideObservations"];
    [self setupReportLocationButtonWithTrackingState:[[defaults objectForKey:kReportLocationKey] boolValue]];
    
    [defaults addObserver:self
               forKeyPath:@"hideObservations"
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    
    [defaults addObserver:self
               forKeyPath:@"hidePeople"
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    
    [defaults addObserver:self
               forKeyPath:kReportLocationKey
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver:self forKeyPath:@"hideObservations"];
    [defaults removeObserver:self forKeyPath:@"hidePeople"];
    [defaults removeObserver:self forKeyPath:kReportLocationKey];
}

- (void)selectedUser:(User *) user {
    LocationAnnotation *annotation = [self.mapDelegate.locationAnnotations objectForKey:user.remoteId];
    [self.mapView selectAnnotation:annotation animated:YES];
    
    [self.mapView setCenterCoordinate:[annotation.location location].coordinate];
    [self performSegueWithIdentifier:@"DisplayPersonSegue" sender:user];
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
    [self performSegueWithIdentifier:@"DisplayObservationSegue" sender:observation];
}

- (void)selectedObservation:(Observation *) observation region:(MKCoordinateRegion) region {
    LocationAnnotation *annotation = [self.mapDelegate.observationAnnotations objectForKey:observation.remoteId];
    
    [self.mapView setRegion:region animated:YES];
    [self.mapView selectAnnotation:annotation animated:YES];
}


-(void) observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([@"hideObservations" isEqualToString:keyPath] && self.mapView) {
        self.mapDelegate.hideObservations = [object boolForKey:keyPath];
    } else if ([@"hidePeople" isEqualToString:keyPath] && self.mapView) {
        self.mapDelegate.hideLocations = [object boolForKey:keyPath];
    } else if ([kReportLocationKey isEqualToString:keyPath] && self.mapView) {
        [self setupReportLocationButtonWithTrackingState:[object boolForKey:keyPath]];
    }
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
    } else if ([segue.identifier isEqualToString:@"CreateNewObservationAtPointSegue"]) {
        ObservationEditViewController *editViewController = segue.destinationViewController;
        
        GeoPoint *point = [[GeoPoint alloc] initWithLocation:self.mapPressLocation];
        
        [editViewController setLocation:point];
    }
}

- (IBAction)onReportLocationButtonPressed:(id)sender {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    BOOL newState =![[defaults objectForKey:kReportLocationKey] boolValue];
    [self setupReportLocationButtonWithTrackingState:newState];
    [defaults setBool:newState forKey:kReportLocationKey];
    [defaults synchronize];
    if (newState) {
        self.toastText.text = @"You are now reporting your location.";
        self.toastView.backgroundColor = [UIColor colorWithRed:76.0/255.0 green:175.0/255.0 blue:80.0/255.0 alpha:1.0];
    } else {
        self.toastText.text = @"Location reporting has been disabled";
        self.toastView.backgroundColor = [UIColor colorWithRed:244.0/255.0 green:67.0/255.0 blue:54.0/255.0 alpha:1.0];
    }
    [self displayToast];
}

- (void) displayToast {
    [self.toastView setHidden:NO];
    self.toastView.alpha = 0.0f;
    [UIView animateWithDuration:0.5f animations:^{
        self.toastView.alpha = 1.0f;
    } completion:^(BOOL finished) {
        [UIView beginAnimations:nil context:NULL];
        [UIView setAnimationDuration:0.5f];
        [UIView setAnimationDelay:2];
        self.toastView.alpha = 0.0f;
        [UIView commitAnimations];
    }];

}

- (void) setupReportLocationButtonWithTrackingState: (BOOL) trackingOn {
    if(trackingOn) {
        [self.reportLocationButton setImage:[UIImage imageNamed:@"location_tracking_on"] forState:UIControlStateNormal];
        [self.reportLocationButton setTintColor:[UIColor colorWithRed:76.0/255.0 green:175.0/255.0 blue:80.0/255.0 alpha:1.0]];
    } else {
        [self.reportLocationButton setImage:[UIImage imageNamed:@"location_tracking_off"] forState:UIControlStateNormal];
        [self.reportLocationButton setTintColor:[UIColor colorWithRed:244.0/255.0 green:67.0/255.0 blue:54.0/255.0 alpha:1.0]];
    }
}

- (IBAction) onTrackingButtonPressed:(id)sender {

    switch (self.mapView.userTrackingMode) {
        case MKUserTrackingModeNone: {
            [self.mapDelegate setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
            break;
        };
        case MKUserTrackingModeFollow: {
            [self.mapDelegate setUserTrackingMode:MKUserTrackingModeFollowWithHeading animated:YES];
            break;
        };
        case MKUserTrackingModeFollowWithHeading: {
            [self.mapDelegate setUserTrackingMode:MKUserTrackingModeNone animated:YES];
            break;
        }
    }
}

-(void) userTrackingModeChanged:(MKUserTrackingMode) mode {
    switch (self.mapView.userTrackingMode) {
        case MKUserTrackingModeNone: {
            [self.trackingButton setImage:[UIImage imageNamed:@"location_arrow_off.png"] forState:UIControlStateNormal];
            break;
        };
        case MKUserTrackingModeFollow: {
            [self.trackingButton setImage:[UIImage imageNamed:@"location_arrow_on.png"] forState:UIControlStateNormal];
            break;
        };
        case MKUserTrackingModeFollowWithHeading: {
            [self.trackingButton setImage:[UIImage imageNamed:@"location_arrow_follow.png"] forState:UIControlStateNormal];
            break;
        }
    }
}

@end

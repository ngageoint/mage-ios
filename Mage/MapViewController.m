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
#import "ImageViewerViewController.h"
#import <Event+helper.h>
#import <GPSLocation+helper.h>

@interface MapViewController ()<UserTrackingModeChanged, LocationAuthorizationStatusChanged>
    @property (weak, nonatomic) IBOutlet UIButton *trackingButton;
    @property (weak, nonatomic) IBOutlet UIButton *reportLocationButton;
    @property (weak, nonatomic) IBOutlet UIView *toastView;
    @property (weak, nonatomic) IBOutlet UILabel *toastText;

    @property (strong, nonatomic) Observations *observationResultsController;
    @property (strong, nonatomic) CLLocation *mapPressLocation;
    @property (nonatomic, strong) NSTimer* locationColorUpdateTimer;
    @property (weak, nonatomic) IBOutlet UILabel *eventNameLabel;

@end

@implementation MapViewController

- (IBAction)mapLongPress:(id)sender {
    UIGestureRecognizer *gestureRecognizer = (UIGestureRecognizer *)sender;
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded && [[Event getCurrentEvent] isUserInEvent:[User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]]]) {
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
    self.mapDelegate.locationAuthorizationChangedDelegate = self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.mapDelegate.hideLocations = [defaults boolForKey:@"hidePeople"];
    self.mapDelegate.hideObservations = [defaults boolForKey:@"hideObservations"];
    Event *currentEvent = [Event getCurrentEvent];
    self.eventNameLabel.text = @"All";
    [self.navigationItem setTitle:currentEvent.name];
    [self setupReportLocationButtonWithTrackingState:[[defaults objectForKey:kReportLocationKey] boolValue] userInEvent:[currentEvent isUserInEvent:[User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]]]];
    
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
    
    //start the timer for updating the circles
    // TODO turn this off on view disappear
    [self scheduleColorUpdateTimer];
    
    [self onLocationAuthorizationStatus:[CLLocationManager authorizationStatus]];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver:self forKeyPath:@"hideObservations"];
    [defaults removeObserver:self forKeyPath:@"hidePeople"];
    [defaults removeObserver:self forKeyPath:kReportLocationKey];
    
    //stop the timer for updating the circles
    if (_locationColorUpdateTimer != nil) {
        [_locationColorUpdateTimer invalidate];
    }
}

- (void) scheduleColorUpdateTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        _locationColorUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(onColorUpdateTimerFire) userInfo:nil repeats:YES];
    });
}

- (void) onColorUpdateTimerFire {
    NSLog(@"Update the colors");
    [self.mapDelegate updateLocations:[self.mapDelegate.locations.fetchedResultsController fetchedObjects]];
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
        [self setupReportLocationButtonWithTrackingState:[object boolForKey:keyPath] userInEvent:[[Event getCurrentEvent] isUserInEvent:[User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]]]];
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
        CLLocation *location = [[LocationService singleton] location];
        if (location == nil) {
            location = [[CLLocation alloc] initWithLatitude:[self.mapView centerCoordinate].latitude longitude:[self.mapView centerCoordinate].longitude];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location Unknown"
                                                            message:@"MAGE was unable to determine your location.  The new observation will be created in the center of the current map view.  Please confirm the location of the observation."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];

        }
        GeoPoint *point = [[GeoPoint alloc] initWithLocation:location];
        [editViewController setLocation:point];
    } else if ([segue.identifier isEqualToString:@"CreateNewObservationAtPointSegue"]) {
        ObservationEditViewController *editViewController = segue.destinationViewController;
        
        GeoPoint *point = [[GeoPoint alloc] initWithLocation:self.mapPressLocation];
        
        [editViewController setLocation:point];
    } else if ([segue.identifier isEqualToString:@"viewImageSegue"]) {
        // Get reference to the destination view controller
        ImageViewerViewController *vc = [segue destinationViewController];
        [vc setAttachment:sender];
        [vc setTitle:@"Attachment"];
    }
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"CreateNewObservationSegue"] || [identifier isEqualToString:@"CreateNewObservationAtPointSegue"]) {
        if (![[Event getCurrentEvent] isUserInEvent:[User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]]]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"You are not part of this event"
                                                            message:@"You cannot create observations for an event you are not part of."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            return false;
        }
    }
    return true;
}

- (IBAction)onReportLocationButtonPressed:(id)sender {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    BOOL newState =![[defaults objectForKey:kReportLocationKey] boolValue];
    User *user = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
    BOOL inEvent = [[Event getCurrentEvent] isUserInEvent:user];
    if (!inEvent) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"You are not part of this event"
                                                        message:@"You cannot report your location for an event you are not part of."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        return;
    } else if (newState) {
        self.toastText.text = @"You are now reporting your location.";
        self.toastView.backgroundColor = [UIColor colorWithRed:76.0/255.0 green:175.0/255.0 blue:80.0/255.0 alpha:1.0];
    } else {
        self.toastText.text = @"Location reporting has been disabled";
        self.toastView.backgroundColor = [UIColor colorWithRed:244.0/255.0 green:67.0/255.0 blue:54.0/255.0 alpha:1.0];
    }
    [self setupReportLocationButtonWithTrackingState:newState userInEvent:inEvent];
    [defaults setBool:newState forKey:kReportLocationKey];
    [defaults synchronize];
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

- (void) setupReportLocationButtonWithTrackingState: (BOOL) trackingOn userInEvent: (BOOL) inEvent {
    if(trackingOn && inEvent) {
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

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self onLocationAuthorizationStatus:status];
}

- (void) onLocationAuthorizationStatus:(CLAuthorizationStatus) status {
    BOOL authorized = status == kCLAuthorizationStatusAuthorizedAlways  || status == kCLAuthorizationStatusAuthorizedWhenInUse;
    [self.trackingButton setHidden:!authorized];
    [self.reportLocationButton setHidden:!authorized];
}

@end

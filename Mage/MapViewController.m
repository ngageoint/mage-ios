//
//  MapViewController.m
//  Mage
//
//

#import "MapViewController.h"

#import "UINavigationItem+Subtitle.h"
#import "AppDelegate.h"
#import "User.h"
#import "Location.h"
#import "LocationAnnotation.h"
#import "LocationService.h"
#import "ObservationAnnotation.h"
#import "Observation.h"
#import "ObservationImage.h"
#import "MeViewController.h"
#import <MapKit/MapKit.h>
#import "Locations.h"
#import "Observations.h"
#import "MageRootViewController.h"
#import "MapDelegate.h"
#import "ObservationEditViewController.h"
#import "LocationAnnotation.h"
#import "ObservationAnnotation.h"
#import "ObservationViewController_iPad.h"
#import "AttachmentViewController.h"
#import "Event.h"
#import "GPSLocation.h"
#import "Filter.h"
#import "WKBPoint.h"

@interface MapViewController ()<UserTrackingModeChanged, LocationAuthorizationStatusChanged, CacheOverlayDelegate>
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
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded && [[Event getCurrentEventInContext:context] isUserInEvent:[User fetchCurrentUserInManagedObjectContext:context]]) {
        CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
        CLLocationCoordinate2D touchMapCoordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
        self.mapPressLocation = [[CLLocation alloc] initWithLatitude:touchMapCoordinate.latitude longitude:touchMapCoordinate.longitude];
        [self performSegueWithIdentifier:@"CreateNewObservationAtPointSegue" sender:sender];
    }
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.mapDelegate.cacheOverlayDelegate = self;
    self.mapDelegate.userTrackingModeDelegate = self;
    self.mapDelegate.locationAuthorizationChangedDelegate = self;
    
    UITapGestureRecognizer * singleTapGesture = [[UITapGestureRecognizer alloc]
                                                 initWithTarget:self action:@selector(singleTapGesture:)];
    singleTapGesture.numberOfTapsRequired = 1;
    [self.mapView addGestureRecognizer:singleTapGesture];
    UITapGestureRecognizer * doubleTapGesture = [[UITapGestureRecognizer alloc]
                                                 initWithTarget:self action:@selector(doubleTapGesture:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    [self.mapView addGestureRecognizer:doubleTapGesture];
    [singleTapGesture requireGestureRecognizerToFail:doubleTapGesture];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    Locations *locations = [Locations locationsForAllUsers];
    [self.mapDelegate setLocations:locations];
    
    Observations *observations = [Observations observations];
    [self.mapDelegate setObservations:observations];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.mapDelegate.hideLocations = [defaults boolForKey:@"hidePeople"];
    self.mapDelegate.hideObservations = [defaults boolForKey:@"hideObservations"];
    
    [self setNavBarTitle];
    
    [defaults addObserver:self
               forKeyPath:kTimeFilterKey
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    
    [defaults addObserver:self
               forKeyPath:kImportantFilterKey
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    
    [defaults addObserver:self
               forKeyPath:kFavortiesFilterKey
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    
    Event *currentEvent = [Event getCurrentEventInContext:[NSManagedObjectContext MR_defaultContext]];
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
    
    // Start the timer for updating the circles
    [self startColorUpdateTimer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidBecomeActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillResignActive)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
    
    [self onLocationAuthorizationStatus:[CLLocationManager authorizationStatus]];
}

- (void) setNavBarTitle {
    NSString *timeFilterString = [Filter getFilterString];
    [self.navigationItem setTitle:[Event getCurrentEventInContext:[NSManagedObjectContext MR_defaultContext]].name subtitle:timeFilterString];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver:self forKeyPath:@"hideObservations"];
    [defaults removeObserver:self forKeyPath:@"hidePeople"];
    [defaults removeObserver:self forKeyPath:kReportLocationKey];
    [defaults removeObserver:self forKeyPath:kTimeFilterKey];
    [defaults removeObserver:self forKeyPath:kFavortiesFilterKey];
    [defaults removeObserver:self forKeyPath:kImportantFilterKey];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];

    [self stopColorUpdateTimer];
}

- (void) applicationWillResignActive {
    [self stopColorUpdateTimer];
}

- (void) applicationDidBecomeActive {
    [self startColorUpdateTimer];
}

- (void) startColorUpdateTimer {
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.locationColorUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(onColorUpdateTimerFire) userInfo:nil repeats:YES];
    });
}

- (void) stopColorUpdateTimer {
    // Stop the timer for updating the circles
    if (self.locationColorUpdateTimer != nil) {
        [self.locationColorUpdateTimer invalidate];
        self.locationColorUpdateTimer = nil;
    }
}

- (void) onColorUpdateTimerFire {
    NSLog(@"Update the user location icon colors");
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
        NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
        [self setupReportLocationButtonWithTrackingState:[object boolForKey:keyPath] userInEvent:[[Event getCurrentEventInContext:context] isUserInEvent:[User fetchCurrentUserInManagedObjectContext:context]]];
    } else if ([kTimeFilterKey isEqualToString:keyPath]) {
        self.mapDelegate.observations = [Observations observations];
        self.mapDelegate.locations = [Locations locationsForAllUsers];
        [self setNavBarTitle];
    } else if ([kImportantFilterKey isEqualToString:keyPath] || [kFavortiesFilterKey isEqualToString:keyPath]) {
        self.mapDelegate.observations = [Observations observations];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    if ([segue.identifier isEqualToString:@"DisplayPersonSegue"]) {
		MeViewController *destinationViewController = segue.destinationViewController;
		[destinationViewController setUser:sender];
    } else if ([segue.identifier isEqualToString:@"DisplayObservationSegue"]) {
        // TODO fix me, this only works because both iPad and iPhone class respond to setObservation
		ObservationViewController_iPad *destinationViewController = segue.destinationViewController;
		[destinationViewController setObservation:sender];
    } else if ([segue.identifier isEqualToString:@"CreateNewObservationSegue"]) {
        ObservationEditViewController *editViewController = segue.destinationViewController;
        CLLocation *location = [[LocationService singleton] location];
        if (location) {
            WKBPoint *point = [[WKBPoint alloc] initWithXValue:location.coordinate.longitude andYValue:location.coordinate.latitude];
            [editViewController setLocation:point];
        }
    } else if ([segue.identifier isEqualToString:@"CreateNewObservationAtPointSegue"]) {
        ObservationEditViewController *editViewController = segue.destinationViewController;
        
        WKBPoint *point = [[WKBPoint alloc] initWithXValue:self.mapPressLocation.coordinate.longitude andYValue:self.mapPressLocation.coordinate.latitude];
        
        [editViewController setLocation:point];
    } else if ([segue.identifier isEqualToString:@"viewImageSegue"]) {
        // Get reference to the destination view controller
        AttachmentViewController *vc = [segue destinationViewController];
        [vc setAttachment:sender];
        [vc setTitle:@"Attachment"];
    }
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"CreateNewObservationSegue"] || [identifier isEqualToString:@"CreateNewObservationAtPointSegue"]) {
        NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
        if (![[Event getCurrentEventInContext:context] isUserInEvent:[User fetchCurrentUserInManagedObjectContext:context]]) {
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:@"You are not part of this event"
                                         message:@"You cannot create observations for an event you are not part of."
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            
            return false;
        }
    }
    
    return true;
}

- (IBAction) onReportLocationButtonPressed:(id)sender {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    BOOL newState =![[defaults objectForKey:kReportLocationKey] boolValue];
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    BOOL inEvent = [[Event getCurrentEventInContext:context] isUserInEvent:[User fetchCurrentUserInManagedObjectContext:context]];
    if (!inEvent) {
        UIAlertController * alert = [UIAlertController alertControllerWithTitle:@"Not In Event"
                                                                        message:@"You cannot report your location for an event you are not part of."
                                                                 preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    } else if (newState) {
        self.toastText.text = @"You are now reporting your location.";
        self.toastView.backgroundColor = [UIColor colorWithRed:76.0/255.0 green:175.0/255.0 blue:80.0/255.0 alpha:1.0];
    } else {
        self.toastText.text = @"Location reporting has been disabled.";
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

- (void) onCacheOverlayTapped:(NSString *)message {
    UIAlertController * alert = [UIAlertController alertControllerWithTitle:nil
                                                                    message:message
                                                             preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

-(void) singleTapGesture:(UITapGestureRecognizer *) tapGestureRecognizer{
    
    if(tapGestureRecognizer.state == UIGestureRecognizerStateEnded){
        CGPoint cgPoint = [tapGestureRecognizer locationInView:self.mapView];
        [self.mapDelegate mapClickAtPoint:cgPoint];
    }
}

-(void) doubleTapGesture:(UITapGestureRecognizer *) tapGestureRecognizer{
    
}

@end

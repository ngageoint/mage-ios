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
#import "FormsViewController.h"
#import "LocationAnnotation.h"
#import "ObservationAnnotation.h"
#import "ObservationViewController_iPad.h"
#import "AttachmentViewController.h"
#import "Event.h"
#import "GPSLocation.h"
#import "Filter.h"
#import "WKBPoint.h"
#import "ObservationEditCoordinator.h"

@interface MapViewController ()<UserTrackingModeChanged, LocationAuthorizationStatusChanged, CacheOverlayDelegate, ObservationEditDelegate>
    @property (weak, nonatomic) IBOutlet UIButton *trackingButton;
    @property (weak, nonatomic) IBOutlet UIButton *reportLocationButton;
    @property (weak, nonatomic) IBOutlet UIView *toastView;
    @property (weak, nonatomic) IBOutlet UILabel *toastText;

    @property (strong, nonatomic) Observations *observationResultsController;
    @property (nonatomic, strong) NSTimer* mapAnnotationsUpdateTimer;
    @property (weak, nonatomic) IBOutlet UILabel *eventNameLabel;
// this property should exist in this view coordinator when we get to that
@property (strong, nonatomic) NSMutableArray *childCoordinators;

@end

@implementation MapViewController

- (IBAction)mapLongPress:(id)sender {
    UIGestureRecognizer *gestureRecognizer = (UIGestureRecognizer *)sender;
    NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded && [[Event getCurrentEventInContext:context] isUserInEvent:[User fetchCurrentUserInManagedObjectContext:context]]) {
        CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
        CLLocationCoordinate2D touchMapCoordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
        CLLocation *mapPressLocation = [[CLLocation alloc] initWithLatitude:touchMapCoordinate.latitude longitude:touchMapCoordinate.longitude];
        
        [self startCreateNewObservationAtLocation:mapPressLocation];
    }
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.childCoordinators = [[NSMutableArray alloc] init];
    
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
               forKeyPath:kObservationTimeFilterKey
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    
    [defaults addObserver:self
               forKeyPath:kObservationTimeFilterUnitKey
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    
    [defaults addObserver:self
               forKeyPath:kObservationTimeFilterNumberKey
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
    
    [defaults addObserver:self
               forKeyPath:kLocationTimeFilterKey
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    
    [defaults addObserver:self
               forKeyPath:kLocationTimeFilterUnitKey
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    
    [defaults addObserver:self
               forKeyPath:kLocationTimeFilterNumberKey
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    
    // Start the timer for updating the circles
    [self startMapAnnotationsUpdateTimer];
    
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
    if ([[Filter getFilterString] length] != 0 || [[Filter getLocationFilterString] length] != 0) {
        [self setNavBarTitle:[Event getCurrentEventInContext:[NSManagedObjectContext MR_defaultContext]].name andSubtitle:@"Showing filtered results."];
    } else {
        [self setNavBarTitle:[Event getCurrentEventInContext:[NSManagedObjectContext MR_defaultContext]].name andSubtitle:nil];
    }
}

- (void) setNavBarTitle: (NSString *) title andSubtitle: (NSString *) subtitle {
    [self.navigationItem setTitle:title subtitle:subtitle];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults removeObserver:self forKeyPath:@"hideObservations"];
    [defaults removeObserver:self forKeyPath:@"hidePeople"];
    [defaults removeObserver:self forKeyPath:kReportLocationKey];
    [defaults removeObserver:self forKeyPath:kObservationTimeFilterKey];
    [defaults removeObserver:self forKeyPath:kObservationTimeFilterUnitKey];
    [defaults removeObserver:self forKeyPath:kObservationTimeFilterNumberKey];
    [defaults removeObserver:self forKeyPath:kLocationTimeFilterKey];
    [defaults removeObserver:self forKeyPath:kLocationTimeFilterUnitKey];
    [defaults removeObserver:self forKeyPath:kLocationTimeFilterNumberKey];
    [defaults removeObserver:self forKeyPath:kFavortiesFilterKey];
    [defaults removeObserver:self forKeyPath:kImportantFilterKey];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];

    [self stopMapAnnotationsUpdateTimer];
}

- (void) applicationWillResignActive {
    [self stopMapAnnotationsUpdateTimer];
}

- (void) applicationDidBecomeActive {
    [self startMapAnnotationsUpdateTimer];
}

- (void) startMapAnnotationsUpdateTimer {
    __weak __typeof__(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.mapAnnotationsUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:self selector:@selector(onMapAnnotationsUpdateTimerFire) userInfo:nil repeats:YES];
    });
}

- (void) stopMapAnnotationsUpdateTimer {
    // Stop the timer for updating the circles
    if (self.mapAnnotationsUpdateTimer != nil) {
        
        [self.mapAnnotationsUpdateTimer invalidate];
        self.mapAnnotationsUpdateTimer = nil;
    }
}

- (void) onMapAnnotationsUpdateTimerFire {
    NSLog(@"Update the user location icon colors");
    [self.mapDelegate updateLocationPredicates:[Locations getPredicatesForLocations]];
    [self.mapDelegate updateObservationPredicates: [Observations getPredicatesForObservations]];
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
    } else if ([kObservationTimeFilterKey isEqualToString:keyPath] || [kObservationTimeFilterUnitKey isEqualToString:keyPath] || [kObservationTimeFilterNumberKey isEqualToString:keyPath]) {
        self.mapDelegate.observations = [Observations observations];
        [self setNavBarTitle];
    } else if ([kLocationTimeFilterKey isEqualToString:keyPath] || [kLocationTimeFilterUnitKey isEqualToString:keyPath] || [kLocationTimeFilterNumberKey isEqualToString:keyPath]) {
        self.mapDelegate.locations = [Locations locationsForAllUsers];
        [self setNavBarTitle];
    } else if ([kImportantFilterKey isEqualToString:keyPath] || [kFavortiesFilterKey isEqualToString:keyPath]) {
        self.mapDelegate.observations = [Observations observations];
        [self setNavBarTitle];
    }
}

- (IBAction)createNewObservation:(id)sender {
    CLLocation *location = [[LocationService singleton] location];
    [self startCreateNewObservationAtLocation:location];
}

- (void) startCreateNewObservationAtLocation: (CLLocation *) location {
    ObservationEditCoordinator *edit;
    WKBPoint *point;
    
    if (location) {
        point = [[WKBPoint alloc] initWithXValue:location.coordinate.longitude andYValue:location.coordinate.latitude];
    }
    edit = [[ObservationEditCoordinator alloc] initWithRootViewController:self andDelegate:self andObservation:nil andLocation:point];
    [self.childCoordinators addObject:edit];
    [edit start];
}

- (void) editComplete:(Observation *)observation {
    
}

- (void) observationDeleted:(Observation *)observation {
    
}


- (void)prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    if ([segue.identifier isEqualToString:@"DisplayPersonSegue"]) {
		MeViewController *destinationViewController = segue.destinationViewController;
		[destinationViewController setUser:sender];
    } else if ([segue.identifier isEqualToString:@"DisplayObservationSegue"]) {
        // TODO fix me, this only works because both iPad and iPhone class respond to setObservation
		ObservationViewController_iPad *destinationViewController = segue.destinationViewController;
		[destinationViewController setObservation:sender];
    } else if ([segue.identifier isEqualToString:@"viewImageSegue"]) {
        // Get reference to the destination view controller
        AttachmentViewController *vc = [segue destinationViewController];
        [vc setAttachment:sender];
        [vc setTitle:@"Attachment"];
    }
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

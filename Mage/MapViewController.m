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
#import "ObservationAnnotationView.h"
#import "MapSettingsCoordinator.h"
#import "Theme+UIResponder.h"
#import "Layer.h"
#import "Server.h"

@interface MapViewController ()<UserTrackingModeChanged, LocationAuthorizationStatusChanged, CacheOverlayDelegate, ObservationEditDelegate, UIViewControllerPreviewingDelegate>
    @property (weak, nonatomic) IBOutlet UIButton *trackingButton;
    @property (weak, nonatomic) IBOutlet UIButton *reportLocationButton;
    @property (weak, nonatomic) IBOutlet UIView *toastView;
    @property (weak, nonatomic) IBOutlet UILabel *toastText;
    @property (weak, nonatomic) IBOutlet UIButton *showPeopleButton;
    @property (weak, nonatomic) IBOutlet UIButton *showObservationsButton;
    @property (weak, nonatomic) IBOutlet UIButton *mapSettingsButton;

    @property (strong, nonatomic) Observations *observationResultsController;
    @property (nonatomic, strong) NSTimer* mapAnnotationsUpdateTimer;
    @property (weak, nonatomic) IBOutlet UILabel *eventNameLabel;
@property (nonatomic, strong) id previewingContext;

@end

@implementation MapViewController

- (IBAction)mapLongPress:(id)sender {
    UIGestureRecognizer *gestureRecognizer = (UIGestureRecognizer *)sender;
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
        CLLocationCoordinate2D touchMapCoordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
        CLLocation *mapPressLocation = [[CLLocation alloc] initWithLatitude:touchMapCoordinate.latitude longitude:touchMapCoordinate.longitude];

        [self startCreateNewObservationAtLocation:mapPressLocation andProvider:@"manual"];
    }
}

- (void) themeDidChange:(MageTheme)theme {
    self.navigationController.navigationBar.barTintColor = [UIColor primary];
    self.navigationController.navigationBar.tintColor = [UIColor navBarPrimaryText];
    self.trackingButton.backgroundColor = [UIColor dialog];
    self.trackingButton.tintColor = [UIColor activeTabIcon];
    self.reportLocationButton.backgroundColor = [UIColor dialog];
    self.mapSettingsButton.backgroundColor = [UIColor dialog];
    self.mapSettingsButton.tintColor = [UIColor activeTabIcon];
    [UIColor themeMap:self.mapView];
    [self setNavBarTitle];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self registerForThemeChanges];
    
    if (@available(iOS 11.0, *)) {
        [self.navigationItem setLargeTitleDisplayMode:UINavigationItemLargeTitleDisplayModeNever];
    } else {
        // Fallback on earlier versions
    }
    
    self.childCoordinators = [[NSMutableArray alloc] init];
    
    self.mapDelegate.cacheOverlayDelegate = self;
    self.mapDelegate.userTrackingModeDelegate = self;
    self.mapDelegate.locationAuthorizationChangedDelegate = self;
    if ([self isForceTouchAvailable]) {
        // don't do this for now.  The previewing context is choosing the annotation that is pressed even if it is below a callout bubble
        //self.mapDelegate.previewDelegate = self;
    }
    
    UITapGestureRecognizer * singleTapGesture = [[UITapGestureRecognizer alloc]
                                                 initWithTarget:self action:@selector(singleTapGesture:)];
    singleTapGesture.numberOfTapsRequired = 1;
    [self.mapView addGestureRecognizer:singleTapGesture];
    UITapGestureRecognizer * doubleTapGesture = [[UITapGestureRecognizer alloc]
                                                 initWithTarget:self action:@selector(doubleTapGesture:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    [self.mapView addGestureRecognizer:doubleTapGesture];
    [singleTapGesture requireGestureRecognizerToFail:doubleTapGesture];
    
    self.showPeopleButton.hidden = YES;
    self.showObservationsButton.hidden = YES;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.mapDelegate.locations != nil) {
        [self.mapDelegate updateLocationPredicates:[Locations getPredicatesForLocations]];
        NSError *error;
        if (![self.mapDelegate.locations.fetchedResultsController performFetch:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        }
    } else {
        Locations *locations = [Locations locationsForAllUsers];
        [self.mapDelegate setLocations:locations];
    }
    
    if (self.mapDelegate.observations != nil) {
        [self.mapDelegate updateObservationPredicates: [Observations getPredicatesForObservationsForMap]];
        NSError *error;
        if (![self.mapDelegate.observations.fetchedResultsController performFetch:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        }
    } else {
        Observations *observations = [Observations observationsForMap];
        [self.mapDelegate setObservations:observations];
    }
    
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
    [self setupShowObservationButtonWithState:![[defaults objectForKey:@"hideObservations"] boolValue]];
    [self setupShowPeopleButtonWithState:![[defaults objectForKey:@"hidePeople"] boolValue]];
    [self setupMapSettingsButton];
    
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
    
    [defaults addObserver:self
               forKeyPath:kCurrentEventIdKey
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

- (BOOL)isForceTouchAvailable {
    BOOL isForceTouchAvailable = NO;
    if ([self.traitCollection respondsToSelector:@selector(forceTouchCapability)]) {
        isForceTouchAvailable = self.traitCollection.forceTouchCapability == UIForceTouchCapabilityAvailable;
    }
    return isForceTouchAvailable;
}

- (UIViewController *)previewingContext:(id<UIViewControllerPreviewing>) previewingContext viewControllerForLocation:(CGPoint)location {
    MKAnnotationView *annotationView = (MKAnnotationView *)previewingContext.sourceView;
    if (self.presentedViewController) {
        return nil;
    }
    
    // this will preview whatever annotation was clicked even if the callout bubble for a different annotation is shown
    // maybe only preview for the annotation which is selected.  Need to figure out how to determine if the annotation callout
    // bubble was pressed
    
    id<MKAnnotation> annotation = annotationView.annotation;
    
    if ([annotation isKindOfClass:[ObservationAnnotation class]]) {
        ObservationAnnotation *observationAnnotation = (ObservationAnnotation *) annotation;
        ObservationViewController *previewController = [self.storyboard instantiateViewControllerWithIdentifier:@"observationViewerViewController"];
        previewController.observation = observationAnnotation.observation;
        return previewController;
    } else if ([annotation isKindOfClass:[LocationAnnotation class]]) {
        LocationAnnotation *locationAnnotation = (LocationAnnotation *) annotation;
        MeViewController *previewController = [self.storyboard instantiateViewControllerWithIdentifier:@"MeViewController"];
        previewController.user = locationAnnotation.location.user;
        return previewController;
    }
    return nil;
}

- (void)previewingContext:(id )previewingContext commitViewController: (UIViewController *)viewControllerToCommit {
    [self.navigationController showViewController:viewControllerToCommit sender:nil];
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
    [defaults removeObserver:self forKeyPath:kCurrentEventIdKey];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];

    [self stopMapAnnotationsUpdateTimer];
    
    [self.mapDelegate cleanup];
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
}

-(void) observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    if ([@"hideObservations" isEqualToString:keyPath] && self.mapView) {
        self.mapDelegate.hideObservations = [object boolForKey:keyPath];
        [self setupShowObservationButtonWithState:![object boolForKey:keyPath]];
    } else if ([@"hidePeople" isEqualToString:keyPath] && self.mapView) {
        self.mapDelegate.hideLocations = [object boolForKey:keyPath];
        [self setupShowPeopleButtonWithState:![object boolForKey:keyPath]];
    } else if ([kReportLocationKey isEqualToString:keyPath] && self.mapView) {
        NSManagedObjectContext *context = [NSManagedObjectContext MR_defaultContext];
        [self setupReportLocationButtonWithTrackingState:[object boolForKey:keyPath] userInEvent:[[Event getCurrentEventInContext:context] isUserInEvent:[User fetchCurrentUserInManagedObjectContext:context]]];
    } else if ([kObservationTimeFilterKey isEqualToString:keyPath] || [kObservationTimeFilterUnitKey isEqualToString:keyPath] || [kObservationTimeFilterNumberKey isEqualToString:keyPath]) {
        self.mapDelegate.observations = [Observations observationsForMap];
        [self setNavBarTitle];
    } else if ([kLocationTimeFilterKey isEqualToString:keyPath] || [kLocationTimeFilterUnitKey isEqualToString:keyPath] || [kLocationTimeFilterNumberKey isEqualToString:keyPath]) {
        self.mapDelegate.locations = [Locations locationsForAllUsers];
        [self setNavBarTitle];
    } else if ([kImportantFilterKey isEqualToString:keyPath] || [kFavortiesFilterKey isEqualToString:keyPath]) {
        self.mapDelegate.observations = [Observations observationsForMap];
        [self setNavBarTitle];
    } else if ([kCurrentEventIdKey isEqualToString:keyPath]) {
        
    }
}

- (IBAction)createNewObservation:(id)sender {
    CLLocation *location = [[LocationService singleton] location];
    [self startCreateNewObservationAtLocation:location andProvider:@"gps"];
}

- (IBAction)mapSettingsButtonTapped:(id)sender {
    MapSettingsCoordinator *settingsCoordinator = [[MapSettingsCoordinator alloc] initWithRootViewController:self.navigationController];
    [self.childCoordinators addObject:settingsCoordinator];
    [settingsCoordinator start];
}

- (void) startCreateNewObservationAtLocation: (CLLocation *) location andProvider: (NSString *) provider {
    ObservationEditCoordinator *edit;
    WKBPoint *point;
    
    CLLocationAccuracy accuracy = 0;
    double delta = 0;
    if (location) {
        if (location.altitude != 0) {
            point = [[WKBPoint alloc] initWithHasZ:YES andHasM:NO andX:[[NSDecimalNumber alloc] initWithDouble: location.coordinate.longitude] andY:[[NSDecimalNumber alloc] initWithDouble:location.coordinate.latitude]];
            [point setZValue:location.altitude];
        } else {
            point = [[WKBPoint alloc] initWithXValue:location.coordinate.longitude andYValue:location.coordinate.latitude];
        }
        accuracy = location.horizontalAccuracy;
        delta = [location.timestamp timeIntervalSinceNow] * -1000;
    }
    edit = [[ObservationEditCoordinator alloc] initWithRootViewController:self andDelegate:self andLocation:point andAccuracy: accuracy andProvider: provider andDelta: delta];
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

- (IBAction)onShowPeopleButtonPressed:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL newState =![[defaults objectForKey:@"hidePeople"] boolValue];
    [self setupShowPeopleButtonWithState:!newState];
    [defaults setBool:newState forKey:@"hidePeople"];
    [defaults synchronize];
}

- (IBAction)onShowObservationsButtonPressed:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL newState =![[defaults objectForKey:@"hideObservations"] boolValue];
    [self setupShowObservationButtonWithState:!newState];
    [defaults setBool:newState forKey:@"hideObservations"];
    [defaults synchronize];
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

- (void) setupShowObservationButtonWithState: (BOOL) showObservations {
    if (showObservations) {
        [self.showObservationsButton setTintColor:[UIColor colorWithRed:76.0/255.0 green:175.0/255.0 blue:80.0/255.0 alpha:1.0]];
    } else {
        [self.showObservationsButton setTintColor:[UIColor colorWithRed:244.0/255.0 green:67.0/255.0 blue:54.0/255.0 alpha:1.0]];
    }
}

- (void) setupShowPeopleButtonWithState: (BOOL) showPeople {
    if (showPeople) {
        [self.showPeopleButton setTintColor:[UIColor colorWithRed:76.0/255.0 green:175.0/255.0 blue:80.0/255.0 alpha:1.0]];
    } else {
        [self.showPeopleButton setTintColor:[UIColor colorWithRed:244.0/255.0 green:67.0/255.0 blue:54.0/255.0 alpha:1.0]];
    }
}

- (void) setupMapSettingsButton {
    NSUInteger count = [Layer MR_countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"eventId == %@ AND type == %@ AND (loaded == 0 || loaded == nil)", [Server currentEventId], @"geopackage"] inContext:[NSManagedObjectContext MR_defaultContext]];
    if (count > 0) {
        UIView *circle = [[UIView alloc] initWithFrame:CGRectMake(self.mapSettingsButton.frame.size.width-10, -10, 20, 20)];
        circle.layer.cornerRadius = 10;
        [circle setBackgroundColor:[UIColor mageBlue]];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"download"]];
        [imageView setFrame:CGRectMake(-2, -2, 24, 24)];
        [imageView setTintColor:[UIColor whiteColor]];
        [circle addSubview:imageView];
        [self.mapSettingsButton addSubview:circle];
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

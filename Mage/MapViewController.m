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
#import <MapKit/MapKit.h>
#import "Locations.h"
#import "Observations.h"
#import "MapDelegate.h"
#import "LocationAnnotation.h"
#import "ObservationAnnotation.h"
#import "Event.h"
#import "GPSLocation.h"
#import "MageFilter.h"
#import "SFPoint.h"
#import "ObservationAnnotationView.h"
#import "Layer.h"
#import "Server.h"
#import "MageConstants.h"
#import "MAGE-Swift.h"
#import <PureLayout.h>

#import "MapSettingsCoordinator.h"
#import "FeatureDetailCoordinator.h"
#import "FilterTableViewController.h"

@interface MapViewController ()<UserTrackingModeChanged, LocationAuthorizationStatusChanged, CacheOverlayDelegate, ObservationEditDelegate, MapSettingsCoordinatorDelegate, FeatureDetailDelegate, AttachmentViewDelegate, UIGestureRecognizerDelegate>
    @property (strong, nonatomic) IBOutlet MDCFloatingButton *trackingButton;
    @property (strong, nonatomic) IBOutlet MDCFloatingButton *reportLocationButton;
    @property (strong, nonatomic) IBOutlet MDCFloatingButton *createFab;
    @property (strong, nonatomic) IBOutlet UIButton *showPeopleButton;
    @property (strong, nonatomic) IBOutlet UIButton *showObservationsButton;
    @property (strong, nonatomic) IBOutlet MDCFloatingButton *mapSettingsButton;
@property (strong, nonatomic) UIStackView *stack;

    @property (strong, nonatomic) Observations *observationResultsController;
    @property (nonatomic, strong) NSTimer* mapAnnotationsUpdateTimer;
    @property (strong, nonatomic) IBOutlet UILabel *eventNameLabel;
    @property (nonatomic) BOOL listenersSetUp;
    @property (weak, nonatomic) id<MKMapViewDelegate> mapEventDelegate;

    @property (nonatomic, strong) id previewingContext;
@end

@implementation MapViewController

- (instancetype) initWithScheme: (id<MDCContainerScheming>) containerScheme andMapEventDelegate: (id<MKMapViewDelegate>) mapEventDelegate {
    if (self = [self initWithScheme:containerScheme]) {
        self.mapEventDelegate = mapEventDelegate;
    }
    return self;
}

- (instancetype) initWithScheme: (id<MDCContainerScheming>) containerScheme {
    if (self = [self init]) {
        self.scheme = containerScheme;
        self.listenersSetUp = false;
    }
    return self;
}

- (LocationService *) getLocationService {
    if (self.locationService) return self.locationService;
    self.locationService = [LocationService singleton];
    return self.locationService;
}

- (IBAction)mapLongPress:(id)sender {
    UIGestureRecognizer *gestureRecognizer = (UIGestureRecognizer *)sender;
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
        CLLocationCoordinate2D touchMapCoordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
        CLLocation *mapPressLocation = [[CLLocation alloc] initWithLatitude:touchMapCoordinate.latitude longitude:touchMapCoordinate.longitude];

        [self startCreateNewObservationAtLocation:mapPressLocation andProvider:@"manual"];
    }
}

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }
    
    self.navigationController.navigationBar.translucent = NO;
    self.navigationController.navigationBar.barTintColor = self.scheme.colorScheme.primaryColorVariant;
    self.navigationController.navigationBar.tintColor = self.scheme.colorScheme.onPrimaryColor;
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : self.scheme.colorScheme.onPrimaryColor};
    self.navigationController.navigationBar.largeTitleTextAttributes = @{NSForegroundColorAttributeName: self.scheme.colorScheme.onPrimaryColor};
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithOpaqueBackground];
    appearance.titleTextAttributes = @{
        NSForegroundColorAttributeName: self.scheme.colorScheme.onPrimaryColor,
        NSBackgroundColorAttributeName: self.scheme.colorScheme.primaryColorVariant
    };
    appearance.largeTitleTextAttributes = @{
        NSForegroundColorAttributeName: self.scheme.colorScheme.onPrimaryColor,
        NSBackgroundColorAttributeName: self.scheme.colorScheme.primaryColorVariant
    };
    
    self.navigationController.navigationBar.standardAppearance = appearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    self.navigationController.navigationBar.standardAppearance.backgroundColor = self.scheme.colorScheme.primaryColorVariant;
    self.navigationController.navigationBar.scrollEdgeAppearance.backgroundColor = self.scheme.colorScheme.primaryColorVariant;
    
    
    self.trackingButton.backgroundColor = self.scheme.colorScheme.surfaceColor;
    self.trackingButton.tintColor = self.scheme.colorScheme.primaryColor;
    self.reportLocationButton.backgroundColor = self.scheme.colorScheme.surfaceColor;
    self.reportLocationButton.tintColor = self.scheme.colorScheme.primaryColor;
    self.mapSettingsButton.backgroundColor = self.scheme.colorScheme.surfaceColor;
    self.mapSettingsButton.tintColor = self.scheme.colorScheme.primaryColor;
    [self.createFab applySecondaryThemeWithScheme:self.scheme];
    [self setNavBarTitle];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    self.stack = [UIStackView newAutoLayoutView];
    self.stack.axis = UILayoutConstraintAxisVertical;
    self.stack.alignment = UIStackViewAlignmentFill;
    self.stack.spacing = 0;
    self.stack.distribution = UIStackViewDistributionFill;
    
    [self.view addSubview:self.stack];
    [self.stack autoPinEdgesToSuperviewSafeArea];
    
    self.mapView = [[MKMapView alloc] initForAutoLayout];
    self.mapView.accessibilityLabel = @"map";
    [self.stack addArrangedSubview:self.mapView];
    
    [self addMapButtons];

    [self.navigationItem setLargeTitleDisplayMode:UINavigationItemLargeTitleDisplayModeNever];
    
    self.childCoordinators = [[NSMutableArray alloc] init];
    self.mapDelegate = [[MapDelegate alloc] init];
    self.mapDelegate.navigationController = [UIApplication getTopViewControllerWithBase:[UIApplication sharedApplication].keyWindow.rootViewController];
    self.mapDelegate.scheme = self.scheme;
    self.mapDelegate.mapStack = self.stack;
    [self.mapDelegate setMapEventDelegte:self.mapEventDelegate];
    self.mapDelegate.mapCalloutDelegate = self;

    [self.mapDelegate setMapView:self.mapView];
    [self.mapView setDelegate:self.mapDelegate];
        
    self.mapDelegate.cacheOverlayDelegate = self;
    self.mapDelegate.userTrackingModeDelegate = self;
    self.mapDelegate.locationAuthorizationChangedDelegate = self;
    self.mapDelegate.canShowUserCallout = YES;
    self.mapDelegate.canShowObservationCallout = YES;
    self.mapDelegate.canShowGpsLocationCallout = YES;
    
    UITapGestureRecognizer *singleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(singleTapGesture:)];
    singleTapGesture.numberOfTapsRequired = 1;
    singleTapGesture.delaysTouchesBegan = YES;
    singleTapGesture.cancelsTouchesInView = YES;
    singleTapGesture.delegate = self;
    [self.mapView addGestureRecognizer:singleTapGesture];
    
    UITapGestureRecognizer * doubleTapGesture = [[UITapGestureRecognizer alloc] init];
    doubleTapGesture.numberOfTapsRequired = 2;
    [self.mapView addGestureRecognizer:doubleTapGesture];
    [singleTapGesture requireGestureRecognizerToFail:doubleTapGesture];
    
    UILongPressGestureRecognizer *longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(mapLongPress:)];
    [self.mapView addGestureRecognizer:longPressGestureRecognizer];
    
    [self applyThemeWithContainerScheme:self.scheme];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.mapDelegate setupListeners];
    
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
    } else {
        Observations *observations = [Observations observationsForMap];
        [self.mapDelegate setObservations:observations];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.mapDelegate.hideLocations = [defaults boolForKey:@"hidePeople"];
    self.mapDelegate.hideObservations = [defaults boolForKey:@"hideObservations"];
    
    [self setNavBarTitle];
    
    [self setupListeners];
    Event *currentEvent = [Event getCurrentEventInContext:[NSManagedObjectContext MR_defaultContext]];
    [self setupReportLocationButtonWithTrackingState:[[defaults objectForKey:kReportLocationKey] boolValue] userInEvent:[currentEvent isUserInEvent:[User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]]]];
    [self setupMapSettingsButton];
    
    

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
    [self.mapDelegate ensureMapLayout];
    [self setupNavigationBar];
}

- (void) setupListeners {
    if (self.listenersSetUp) return;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

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
               forKeyPath:GeoPackageImported
                  options:NSKeyValueObservingOptionNew
                  context:NULL];
    
    self.listenersSetUp = true;
}

- (void) addMapButtons {
    UIStackView *buttonStack = [[UIStackView alloc] initForAutoLayout];
    buttonStack.alignment = UIStackViewAlignmentFill;
    buttonStack.distribution = UIStackViewDistributionFill;
    buttonStack.spacing = 10;
    buttonStack.axis = UILayoutConstraintAxisVertical;
    buttonStack.translatesAutoresizingMaskIntoConstraints = false;
    buttonStack.layoutMarginsRelativeArrangement = true;
    
    self.mapSettingsButton = [MDCFloatingButton floatingButtonWithShape:MDCFloatingButtonShapeMini];
    [self.mapSettingsButton setImage:[UIImage imageNamed:@"layers"] forState:UIControlStateNormal];
    [self.mapSettingsButton addTarget:self action:@selector(mapSettingsButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    self.trackingButton = [MDCFloatingButton floatingButtonWithShape:MDCFloatingButtonShapeMini];
    [self.trackingButton setImage:[UIImage imageNamed:@"location_arrow_off"] forState:UIControlStateNormal];
    [self.trackingButton addTarget:self action:@selector(onTrackingButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    self.reportLocationButton = [MDCFloatingButton floatingButtonWithShape:MDCFloatingButtonShapeMini];
    [self.reportLocationButton setImage:[UIImage imageNamed:@"location_tracking_off"] forState:UIControlStateNormal];
    [self.reportLocationButton addTarget:self action:@selector(onReportLocationButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    self.createFab = [MDCFloatingButton floatingButtonWithShape:MDCFloatingButtonShapeDefault];
    [self.createFab setImage:[UIImage imageNamed:@"add_location"] forState:UIControlStateNormal];
    [self.createFab addTarget:self action:@selector(createNewObservation:) forControlEvents:UIControlEventTouchUpInside];
    self.createFab.accessibilityLabel = @"New";
    
    [buttonStack addArrangedSubview:self.trackingButton];
    [buttonStack addArrangedSubview:self.reportLocationButton];
    
    [self.view insertSubview:self.mapSettingsButton aboveSubview:self.mapView];
    [self.mapSettingsButton autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.mapView withOffset:25];
    [self.mapSettingsButton autoPinEdgeToSuperviewMargin:ALEdgeRight];
    
    [self.view insertSubview:buttonStack aboveSubview:self.mapView];
    [buttonStack autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.mapView withOffset:25];
    [buttonStack autoPinEdgeToSuperviewMargin:ALEdgeLeft];
    
    [self.view insertSubview:self.createFab aboveSubview:self.mapView];
    [self.createFab autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.mapView withOffset:-25];
    [self.createFab autoPinEdgeToSuperviewMargin:ALEdgeRight];
}

- (IBAction)filterTapped:(id)sender {
    UIStoryboard *filterStoryboard = [UIStoryboard storyboardWithName:@"Filter" bundle:nil];
    UINavigationController *vc = (UINavigationController *)[filterStoryboard instantiateInitialViewController];
    FilterTableViewController *fvc = (FilterTableViewController *)vc.topViewController;
    [fvc applyThemeWithContainerScheme:self.scheme];
    vc.modalPresentationStyle = UIModalPresentationPopover;
    vc.popoverPresentationController.barButtonItem = sender;
    [self presentViewController:vc animated:YES completion:nil];
}

- (void) setupNavigationBar {
    UIBarButtonItem *filterButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"filter"] style:UIBarButtonItemStylePlain target:self action:@selector(filterTapped:)];
    self.navigationItem.rightBarButtonItems = @[filterButton];
}

- (void) setNavBarTitle {
    if ([[MageFilter getFilterString] length] != 0 || [[MageFilter getLocationFilterString] length] != 0) {
        [self setNavBarTitle:[Event getCurrentEventInContext:[NSManagedObjectContext MR_defaultContext]].name andSubtitle:@"Showing filtered results."];
    } else {
        [self setNavBarTitle:[Event getCurrentEventInContext:[NSManagedObjectContext MR_defaultContext]].name andSubtitle:nil];
    }
}

- (void) setNavBarTitle: (NSString *) title andSubtitle: (NSString *) subtitle {
    [self.navigationItem setTitle:title subtitle:subtitle scheme:self.scheme];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    @try {
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
        [defaults removeObserver:self forKeyPath:GeoPackageImported];
    }
    @catch (id exception) {
        NSLog(@"Exception removing observers %@", exception);
    }
    
    self.listenersSetUp = false;
    
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
    self.mapAnnotationsUpdateTimer = [NSTimer timerWithTimeInterval:60 target:self selector:@selector(onMapAnnotationsUpdateTimerFire) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.mapAnnotationsUpdateTimer forMode:NSDefaultRunLoopMode];
}

- (void) stopMapAnnotationsUpdateTimer {
    // Stop the timer for updating the circles
    if (self.mapAnnotationsUpdateTimer != nil) {
        
        [self.mapAnnotationsUpdateTimer invalidate];
        self.mapAnnotationsUpdateTimer = nil;
    }
}

- (void) onMapAnnotationsUpdateTimerFire {
    [self.mapDelegate updateLocationPredicates:[Locations getPredicatesForLocations]];
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
        self.mapDelegate.observations = [Observations observationsForMap];
        [self setNavBarTitle];
    } else if ([kLocationTimeFilterKey isEqualToString:keyPath] || [kLocationTimeFilterUnitKey isEqualToString:keyPath] || [kLocationTimeFilterNumberKey isEqualToString:keyPath]) {
        self.mapDelegate.locations = [Locations locationsForAllUsers];
        [self setNavBarTitle];
    } else if ([kImportantFilterKey isEqualToString:keyPath] || [kFavortiesFilterKey isEqualToString:keyPath]) {
        self.mapDelegate.observations = [Observations observationsForMap];
        [self setNavBarTitle];
    } else if ([GeoPackageImported isEqualToString:keyPath]) {
        [self setupMapSettingsButton];
    }
}

- (IBAction)createNewObservation:(id)sender {
    CLLocation *location = [[self getLocationService] location];
    [self startCreateNewObservationAtLocation:location andProvider:@"gps"];
}

- (IBAction)mapSettingsButtonTapped:(id)sender {
    MapSettingsCoordinator *settingsCoordinator = [[MapSettingsCoordinator alloc] initWithRootViewController:self.navigationController scheme:self.scheme];
    settingsCoordinator.delegate = self;
    [self.childCoordinators addObject:settingsCoordinator];
    [settingsCoordinator start];
}

- (void) startCreateNewObservationAtLocation: (CLLocation *) location andProvider: (NSString *) provider {
    ObservationEditCoordinator *edit;
    SFPoint *point;
    
    CLLocationAccuracy accuracy = 0;
    double delta = 0;
    if (location) {
        if (location.altitude != 0) {
            point = [[SFPoint alloc] initWithHasZ:YES andHasM:NO andX:[[NSDecimalNumber alloc] initWithDouble: location.coordinate.longitude] andY:[[NSDecimalNumber alloc] initWithDouble:location.coordinate.latitude]];
            [point setZValue:location.altitude];
        } else {
            point = [[SFPoint alloc] initWithXValue:location.coordinate.longitude andYValue:location.coordinate.latitude];
        }
        accuracy = location.horizontalAccuracy;
        delta = [location.timestamp timeIntervalSinceNow] * -1000;
    }
    
    edit = [[ObservationEditCoordinator alloc] initWithRootViewController:self delegate:self location:point accuracy:accuracy provider:provider delta:delta];
    [edit applyThemeWithContainerScheme:self.scheme];
    
    [self.childCoordinators addObject:edit];
    [edit start];
}

- (void) doneViewingWithCoordinator:(NSObject *)coordinator {
    [self.childCoordinators removeObject:coordinator];
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
        [MDCSnackbarManager.defaultManager showMessage:[MDCSnackbarMessage messageWithText:@"You are now reporting your location"]];
    } else {
        [MDCSnackbarManager.defaultManager showMessage:[MDCSnackbarMessage messageWithText:@"Location reporting has been disabled"]];
    }
    [self setupReportLocationButtonWithTrackingState:newState userInEvent:inEvent];
    [defaults setBool:newState forKey:kReportLocationKey];
    [defaults synchronize];
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

- (void) setupMapSettingsButton {
    NSUInteger count = [Layer MR_countOfEntitiesWithPredicate:[NSPredicate predicateWithFormat:@"eventId == %@ AND type == %@ AND (loaded == 0 || loaded == nil)", [Server currentEventId], @"GeoPackage"] inContext:[NSManagedObjectContext MR_defaultContext]];
    if (count > 0) {
        UIView *circle = [[UIView alloc] initWithFrame:CGRectMake(25, -10, 20, 20)];
        circle.tag = 998;
        circle.layer.cornerRadius = 10;
        circle.layer.borderWidth = .5;
        circle.layer.borderColor = [[self.scheme.colorScheme.onPrimaryColor colorWithAlphaComponent:0.6] CGColor];
        [circle setBackgroundColor:self.scheme.colorScheme.primaryColorVariant];
        UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"download"]];
        [imageView setFrame:CGRectMake(3, 2, 14, 15)];
        [imageView setTintColor:self.scheme.colorScheme.onPrimaryColor];
        [circle addSubview:imageView];
        [self.mapSettingsButton addSubview:circle];
    } else {
        for (UIView *subview in self.mapSettingsButton.subviews) {
            if (subview.tag == 998) {
                [subview removeFromSuperview];
            }
        }
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
            [self.mapDelegate startHeading];
            [self.trackingButton setImage:[UIImage imageNamed:@"location_arrow_on.png"] forState:UIControlStateNormal];
            break;
        };
        case MKUserTrackingModeFollowWithHeading: {
            [self.mapDelegate startHeading];
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
    NSAttributedString *attributedMessage = [[NSMutableAttributedString alloc] initWithData:[message dataUsingEncoding:NSUTF8StringEncoding]
                                                                                    options:@{NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
                                                                                              NSCharacterEncodingDocumentAttribute: @(NSUTF8StringEncoding)}
                                                                         documentAttributes:nil
                                                                                      error:nil];
    FeatureDetailCoordinator *detailCoordinator = [[FeatureDetailCoordinator alloc] initWithViewController:self detail:attributedMessage containerScheme:self.scheme];
    detailCoordinator.delegate = self;
    [detailCoordinator start];
    [self.childCoordinators addObject:detailCoordinator];
}

-(void) singleTapGesture:(UITapGestureRecognizer *) tapGestureRecognizer {
    if (tapGestureRecognizer.state == UIGestureRecognizerStateEnded){
        CGPoint cgPoint = [tapGestureRecognizer locationInView:self.mapView];
        [self.mapDelegate mapClickAtPoint:cgPoint];
    }
}

#pragma mark - Observation Edit Coordinator Delegate

- (void) editCancel:(NSObject *) coordinator {
    [self.childCoordinators removeObject:coordinator];
}

- (void) editComplete:(Observation *)observation coordinator:(NSObject *) coordinator {
    [self.childCoordinators removeObject:coordinator];
}

#pragma mark - Feature Detail Coordinator Delegate

- (void) featureDetailComplete:(NSObject *)coordinator {
    [self.childCoordinators removeObject:coordinator];
}

#pragma mark - Map Settings Coordinator Delegate

- (void) mapSettingsComplete:(NSObject *) coordinator {
    [self.childCoordinators removeObject:coordinator];
}


#pragma mark - Map Callout Tapped
-(void) calloutTapped:(id) calloutItem {
    if ([calloutItem isKindOfClass:[User class]]) {
        [self userDetailSelected:(User *) calloutItem];
    } else if ([calloutItem isKindOfClass:[Observation class]]) {
        [self observationDetailSelected:(Observation *) calloutItem];
    } else if ([calloutItem isKindOfClass:[FeedItem class]]) {
        [self feedItemSelected:(FeedItem *) calloutItem];
    }
}

- (void) userDetailSelected:(User *) user {
//    [self.mapDelegate selectedUser:user];
    UserViewController *uc = [[UserViewController alloc] initWithUser:user scheme:self.scheme];
    [self.navigationController pushViewController:uc animated:YES];
}

- (void)observationDetailSelected:(Observation *)observation {
    [self.mapDelegate observationDetailSelected:observation];
    ObservationViewCardCollectionViewController *ovc = [[ObservationViewCardCollectionViewController alloc] initWithObservation:observation scheme:self.scheme];
    [self.navigationController pushViewController:ovc animated:YES];
}

- (void) feedItemSelected:(FeedItem *)feedItem {
    FeedItemViewController *fivc = [[FeedItemViewController alloc] initWithFeedItem:feedItem scheme:self.scheme];
    [self.navigationController pushViewController:fivc animated:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    CGPoint point = [gestureRecognizer locationInView:self.mapView];
    if ([otherGestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] && ((UITapGestureRecognizer *) otherGestureRecognizer).numberOfTapsRequired == 1) {
        CLLocationCoordinate2D location = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
        MapShapeObservation *mapShapeObservation = [self.mapDelegate.mapObservations clickedShapeAtLocation:location];
        if (mapShapeObservation != nil) {
            return YES;
        }
    }
    
    return NO;
}

@end

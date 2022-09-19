//
//  GeometryEditViewController.m
//  MAGE
//
//

#import "GeometryEditViewController.h"
#import "LocationService.h"
#import "SFPoint.h"
#import "SFGeometryUtils.h"
#import "MapObservation.h"
#import "MapObservationManager.h"
#import "GPKGMapShapeConverter.h"
#import "MapShapePointsObservation.h"
#import "MapAnnotationObservation.h"
#import "MapShapePointAnnotationView.h"
#import "PROJProjectionConstants.h"
#import "SFGeometryEnvelopeBuilder.h"
#import "ObservationShapeStyle.h"
#import "UINavigationItem+Subtitle.h"
#import "MapUtils.h"
#import "GPKGGeoPackageFactory.h"
#import "AppDelegate.h"
#import <PureLayout/PureLayout.h>
#import "MAGE-Swift.h"


@import MaterialComponents;

static float paddingPercentage = .1;
static NSString *latLngTitle = @"Lat / Lng";
static NSString *mgrsTitle = @"MGRS";
static NSString *dmsTitle = @"DMS";
static NSString *garsTitle = @"GARS";


@interface GeometryEditViewController()<UITextFieldDelegate, EditableMapAnnotationDelegate, MDCTabBarViewDelegate, CoordinateFieldDelegate>

@property (strong, nonatomic) GeometryEditCoordinator *coordinator;
@property (strong, nonatomic) SFGeometry *geometry;

@property (strong, nonatomic) MapObservation *mapObservation;
@property (strong, nonatomic) MapObservationManager *observationManager;
@property (strong, nonatomic) GPKGMapShapeConverter *shapeConverter;
@property (nonatomic) BOOL newDrawing;
@property (nonatomic) enum SFGeometryType shapeType;
@property (nonatomic) BOOL isRectangle;
@property (strong, nonatomic) GPKGMapPoint *rectangleSameXMarker;
@property (strong, nonatomic) GPKGMapPoint *rectangleSameYMarker;
@property (nonatomic) BOOL rectangleSameXSide1;
@property (nonatomic) BOOL validLocation;
@property (strong, nonatomic) NSString *mapCoordinateSystem;
@property (strong, nonatomic) NSString *currentCoordinateSystem;
@property (strong, nonatomic) MKTileOverlay *tileOverlay;

// DMS
@property (strong, nonatomic) CoordinateField *dmsLatitudeField;
@property (strong, nonatomic) CoordinateField *dmsLongitudeField;

@property (strong, nonatomic) MDCFilledTextField *latitudeField;
@property (strong, nonatomic) MDCFilledTextField *longitudeField;
@property (strong, nonatomic) MDCFilledTextField *mgrsField;
@property (strong, nonatomic) MDCFilledTextField *garsField;
@property (strong, nonatomic) NSNumberFormatter *decimalFormatter;
@property (nonatomic) double lastAnnotationSelectedTime;
@property (nonatomic, strong) Observation *observation;
@property (strong, nonatomic) GPKGMapPoint *selectedMapPoint;
@property (nonatomic) BOOL isObservationGeometry;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;

@property (strong, nonatomic) MDCFloatingButton *pointButton;
@property (strong, nonatomic) MDCFloatingButton *lineButton;
@property (strong, nonatomic) MDCFloatingButton *rectangleButton;
@property (strong, nonatomic) MDCFloatingButton *polygonButton;

@property (strong, nonatomic) UIScrollView *slidescroll;
@property (strong, nonatomic) MDCTabBarView *fieldTypeTabs;
@property (strong, nonatomic) UIView *hintView;
@property (strong, nonatomic) UILabel *hintLabel;
@end

@implementation GeometryEditViewController

#define degreesToRadians(x) (M_PI * x / 180.0)
#define radiansToDegrees(x) (x * 180.0 / M_PI)

- (void) themeTextField: (MDCFilledTextField *) field withScheme: (id<MDCContainerScheming>)containerScheme {
    [field applyThemeWithScheme:containerScheme];
    [field setFilledBackgroundColor:[containerScheme.colorScheme.surfaceColor colorWithAlphaComponent:0.87] forState:MDCTextControlStateNormal];
    [field setFilledBackgroundColor:[containerScheme.colorScheme.surfaceColor colorWithAlphaComponent:0.87] forState:MDCTextControlStateEditing];
}

- (void) applyThemeTextField: (MDCFilledTextField *) field {
    [self themeTextField:field withScheme:self.scheme];
}

- (void) applyErrorThemeTextField: (MDCFilledTextField *) field {
    [self themeTextField:field withScheme:[MAGEErrorScheme scheme]];
}

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    self.scheme = containerScheme;
    self.navigationController.navigationBar.translucent = NO;
    self.slidescroll.backgroundColor = containerScheme.colorScheme.primaryColor;
    [self.fieldTypeTabs applyPrimaryThemeWithScheme:self.scheme];
    [self applyThemeTextField:self.latitudeField];
    [self applyThemeTextField:self.longitudeField];
    [self applyThemeTextField:self.mgrsField];
    
    // DMS
    [self.dmsLatitudeField applyThemeWithScheme:containerScheme];
    [self.dmsLongitudeField applyThemeWithScheme:containerScheme];
    
    [self applyThemeTextField:self.garsField];
    
    self.hintView.backgroundColor = containerScheme.colorScheme.primaryColor;
    self.hintLabel.textColor = containerScheme.colorScheme.onSecondaryColor;
    
    [self setShapeTypeSelection];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    // this will force the offline map to update
    [self setupMapType:[NSUserDefaults standardUserDefaults]];
}

- (void) addLeadingIconConstraints: (UIImageView *) leadingIcon {
    NSLayoutConstraint *constraint0 = [NSLayoutConstraint constraintWithItem: leadingIcon attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeWidth multiplier:1.0f constant: 30];
    NSLayoutConstraint *constraint1 = [NSLayoutConstraint constraintWithItem: leadingIcon attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:1.0f constant: 20];
    [leadingIcon addConstraint:constraint0];
    [leadingIcon addConstraint:constraint1];
    leadingIcon.contentMode = UIViewContentModeScaleAspectFit;
}

-(void) setShapeTypeSelection {
    [self updateButton:self.pointButton toSelected:self.shapeType == SF_POINT];
    [self updateButton:self.lineButton toSelected:self.shapeType == SF_LINESTRING];
    [self updateButton:self.rectangleButton toSelected:self.shapeType == SF_POLYGON && self.isRectangle];
    [self updateButton:self.polygonButton toSelected:self.shapeType == SF_POLYGON && !self.isRectangle];
}

- (void) updateButton: (UIButton *) button toSelected: (BOOL) selected {
    if (selected) {
        [button setTintColor:self.scheme.colorScheme.primaryColor];
        [button setBackgroundColor:self.scheme.colorScheme.surfaceColor];
    } else {
        [button setTintColor:[UIColor.systemGrayColor colorWithAlphaComponent:0.6]];
        [button setBackgroundColor:self.scheme.colorScheme.surfaceColor];
    }
}

- (instancetype) initWithCoordinator:(GeometryEditCoordinator *) coordinator scheme: (id<MDCContainerScheming>) containerScheme {
    if (self = [super initWithNibName:nil bundle:nil]) {
        _mapDelegate = [[GeometryEditMapDelegate alloc] initWithDragCallback:self andEditDelegate:self];
        _coordinator = coordinator;
        _scheme = containerScheme;
        
        UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"xmark"] style:UIBarButtonItemStylePlain target:self action:@selector(fieldEditCanceled)];
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Apply" style:UIBarButtonItemStyleDone target:self action:@selector(fieldEditDone)];
        doneButton.isAccessibilityElement = true;
        doneButton.accessibilityLabel = @"Apply";
        
        UIBarButtonItem *clearButton;
        __weak typeof(self) weakSelf = self;
        UIAction *clearAction = [UIAction actionWithTitle:@"Clear" image:nil identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [weakSelf clearLocation];
        }];
        clearAction.accessibilityLabel = @"clear";
        
        UIMenu *clearMenu = [UIMenu menuWithTitle:@"" children:@[clearAction]];
        UIImage *moreImage = [UIImage imageNamed:@"more_small"];
        moreImage.accessibilityLabel = @"more_menu";
        clearButton = [[UIBarButtonItem alloc] initWithImage:moreImage menu:clearMenu];
        clearButton.isAccessibilityElement = true;
        clearButton.accessibilityLabel = @"more_menu";
        [self.navigationItem setLeftBarButtonItem:backButton];
        [self.navigationItem setRightBarButtonItems:@[clearButton, doneButton]];
    }
    return self;
}

- (void) clearLocation {
    self.geometry = nil;
    [self updateGeometry];
    self.latitudeField.text = nil;
    self.longitudeField.text = nil;
    self.mgrsField.text = nil;
    self.dmsLatitudeField.text = nil;
    self.dmsLongitudeField.text = nil;
    self.garsField.text = nil;
    if(self.mapObservation != nil){
        [self.mapObservation removeFromMapView:self.map];
        self.mapObservation = nil;
    }
}

- (void) fieldEditCanceled {
    [self.coordinator fieldEditCanceled];
}

- (void) fieldEditDone {
    // Validate the geometry
    NSError *error;
    if (![self validate:&error]) {
        NSString *message = [[error userInfo] valueForKey:NSLocalizedDescriptionKey];
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Invalid Geometry"
                                                                       message:message
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        
        [self.navigationController presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    [self.coordinator fieldEditDone];
}

- (void) setupMapType: (id) object {
    NSInteger mapType = [object integerForKey:@"mapType"];
    if (mapType == 3) {
        [self addBackgroundMap];
    } else {
        self.map.mapType = [object integerForKey:@"mapType"];
        [self removeBackgroundMap];
    }
}

- (void) setupGridType: (id) object {
    NSInteger gridType = [object integerForKey:@"gridType"];
    NSString *coordinateSystem = nil;
    switch(gridType){
        case GridTypeGARS:
            coordinateSystem = garsTitle;
            break;
        case GridTypeMGRS:
            coordinateSystem = mgrsTitle;
            break;
        default:
            coordinateSystem = latLngTitle;
            break;
    }
    self.mapCoordinateSystem = coordinateSystem;
}

- (void) addBackgroundMap {
    BaseMapOverlay *backgroundOverlay = [((AppDelegate *)[UIApplication sharedApplication].delegate) getBaseMap];
    BaseMapOverlay *darkBackgroundOverlay = [((AppDelegate *)[UIApplication sharedApplication].delegate) getDarkBaseMap];
    if (UITraitCollection.currentTraitCollection.userInterfaceStyle == UIUserInterfaceStyleDark) {
        [self.map removeOverlay:backgroundOverlay];
        [self.map addOverlay:darkBackgroundOverlay level:MKOverlayLevelAboveRoads];
    } else {
        NSLog(@"Adding the background map");
        [self.map removeOverlay:darkBackgroundOverlay];
        [self.map addOverlay:backgroundOverlay level:MKOverlayLevelAboveRoads];
    }
}

- (void) removeBackgroundMap {
    BaseMapOverlay *backgroundOverlay = [((AppDelegate *)[UIApplication sharedApplication].delegate) getBaseMap];
    BaseMapOverlay *darkBackgroundOverlay = [((AppDelegate *)[UIApplication sharedApplication].delegate) getDarkBaseMap];
    [self.map removeOverlay: backgroundOverlay];
    [self.map removeOverlay: darkBackgroundOverlay];
}

- (void) buildView {
    self.map = [[MKMapView alloc] initForAutoLayout];
    self.map.accessibilityLabel = @"Geometry Edit Map";
    [self.view addSubview:self.map];
    [self.map autoPinEdgesToSuperviewEdges];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self setupMapType:defaults];
    
    [self setupGridType:defaults];
    
    // field type tabs
    self.fieldTypeTabs = [[MDCTabBarView alloc] init];
    UITabBarItem *latlngTab = [[UITabBarItem alloc] initWithTitle:latLngTitle image:nil tag:0];
    latlngTab.accessibilityLabel = @"Latitude Longitude";
    UITabBarItem *mgrsTab = [[UITabBarItem alloc] initWithTitle:mgrsTitle image:nil tag:1];
    mgrsTab.accessibilityLabel = @"MGRS";
    UITabBarItem *dmsTab = [[UITabBarItem alloc] initWithTitle:dmsTitle image:nil tag:2];
    dmsTab.accessibilityLabel = @"DMS";
    UITabBarItem *garsTab = [[UITabBarItem alloc] initWithTitle:garsTitle image:nil tag:3];
    garsTab.accessibilityLabel = @"GARS";
    self.fieldTypeTabs.items = @[latlngTab, mgrsTab, dmsTab, garsTab];
    self.fieldTypeTabs.preferredLayoutStyle = MDCTabBarViewLayoutStyleFixed;
    NSInteger tabIndex = defaults.locationDisplay;
    [self.fieldTypeTabs setSelectedItem:[self.fieldTypeTabs.items objectAtIndex:tabIndex]];
    
    self.fieldTypeTabs.tabBarDelegate = self;
    [self.view addSubview:self.fieldTypeTabs];
    [self.fieldTypeTabs autoPinEdgesToSuperviewSafeAreaWithInsets:UIEdgeInsetsZero excludingEdge:ALEdgeBottom];
    
    // tab content
    self.slidescroll = [[UIScrollView alloc] initForAutoLayout];
    [self.slidescroll setScrollEnabled:false];
    self.slidescroll.contentSize = CGSizeMake(3.0 * self.view.bounds.size.width, 150);
    [self.slidescroll setUserInteractionEnabled:true];
    UIStackView *tabStack = [[UIStackView alloc] initForAutoLayout];
    tabStack.axis = UILayoutConstraintAxisHorizontal;
    tabStack.spacing = 0.0;
    tabStack.distribution = UIStackViewDistributionFill;
    tabStack.directionalLayoutMargins = NSDirectionalEdgeInsetsZero;
    tabStack.clipsToBounds = true;
    [tabStack setUserInteractionEnabled:true];
    [self.slidescroll addSubview:tabStack];
    [self.view addSubview:self.slidescroll];
    [self.slidescroll autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.slidescroll autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.slidescroll autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.fieldTypeTabs];
    [tabStack autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.slidescroll];
    
    self.latitudeField = [[MDCFilledTextField alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    self.latitudeField.placeholder = @"Latitude";
    self.latitudeField.label.text = @"Latitude";
    self.latitudeField.accessibilityLabel = @"Latitude Value";
    [self.latitudeField sizeToFit];
    
    self.longitudeField = [[MDCFilledTextField alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    self.longitudeField.placeholder = @"Longitude";
    self.longitudeField.label.text = @"Longitude";
    self.longitudeField.accessibilityLabel = @"Longitude Value";
    [self.longitudeField sizeToFit];
    
    self.mgrsField = [[MDCFilledTextField alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    self.mgrsField.placeholder = @"MGRS";
    self.mgrsField.label.text = @"MGRS";
    self.mgrsField.accessibilityLabel = @"MGRS Value";
    [self.mgrsField sizeToFit];
    
    // DMS
    self.dmsLatitudeField = [[CoordinateField alloc] initWithLatitude: true text:nil label:@"Latitude DMS" delegate: self scheme:self.scheme];
    self.dmsLatitudeField.accessibilityLabel = @"Latitude DMS Value";
    [self.dmsLatitudeField sizeToFit];
    
    self.dmsLongitudeField = [[CoordinateField alloc] initWithLatitude: false text:nil label:@"Longitude DMS" delegate: self scheme:self.scheme];
    self.dmsLongitudeField.accessibilityLabel = @"Longitude DMS Value";
    [self.dmsLongitudeField sizeToFit];
    self.dmsLatitudeField.linkedLongitudeField = self.dmsLongitudeField;
    
    self.garsField = [[MDCFilledTextField alloc] initWithFrame:CGRectMake(0, 0, 200, 100)];
    self.garsField.placeholder = @"GARS";
    self.garsField.label.text = @"GARS";
    self.garsField.accessibilityLabel = @"GARS Value";
    [self.garsField sizeToFit];
    
    UIView *latlngContainer = [[UIView alloc] initForAutoLayout];
    [latlngContainer addSubview:_latitudeField];
    [latlngContainer addSubview:_longitudeField];
    
    UIView *mgrsContainer = [[UIView alloc] initForAutoLayout];
    [mgrsContainer addSubview:self.mgrsField];
    
    [tabStack addArrangedSubview:latlngContainer];
    [tabStack addArrangedSubview:mgrsContainer];
    
    [latlngContainer autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.slidescroll];
    [mgrsContainer autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.slidescroll];
    
    [self.latitudeField autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(8, 8, 8, 8) excludingEdge:ALEdgeRight];
    [self.longitudeField autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(8, 8, 8, 8) excludingEdge:ALEdgeLeft];
    [self.longitudeField autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.latitudeField withOffset:8];
    [self.latitudeField autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.longitudeField];
    [self.mgrsField autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(8, 8, 8, 8)];
    
    // DMS
    UIView *dmsContainer = [[UIView alloc] initForAutoLayout];
    [dmsContainer addSubview:self.dmsLatitudeField];
    [dmsContainer addSubview:self.dmsLongitudeField];
    
    [tabStack addArrangedSubview:dmsContainer];
    [dmsContainer autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.slidescroll];
    
    [self.dmsLatitudeField autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(8, 8, 8, 8) excludingEdge:ALEdgeRight];
    [self.dmsLongitudeField autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(8, 8, 8, 8) excludingEdge:ALEdgeLeft];
    [self.dmsLongitudeField autoPinEdge:ALEdgeLeft toEdge:ALEdgeRight ofView:self.dmsLatitudeField withOffset:8];
    [self.dmsLatitudeField autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.dmsLongitudeField];
    
    UIView *garsContainer = [[UIView alloc] initForAutoLayout];
    [garsContainer addSubview:self.garsField];
    [tabStack addArrangedSubview:garsContainer];
    [garsContainer autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.slidescroll];
    [self.garsField autoPinEdgesToSuperviewEdgesWithInsets:UIEdgeInsetsMake(8, 8, 8, 8)];
    
    self.hintView = [[UIView alloc] initForAutoLayout];
    [self.hintView autoSetDimension:ALDimensionHeight toSize:16];
    self.hintLabel = [[UILabel alloc] initForAutoLayout];
    [self.hintView addSubview:self.hintLabel];
    [self.hintLabel autoCenterInSuperview];
    [self.hintLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.hintView];
    self.hintLabel.textAlignment = NSTextAlignmentCenter;
    self.hintLabel.font = [UIFont systemFontOfSize:10];
    
    [self.view addSubview:self.hintView];
    [self.hintView autoPinEdgeToSuperviewEdge:ALEdgeLeft];
    [self.hintView autoPinEdgeToSuperviewEdge:ALEdgeRight];
    [self.hintView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.slidescroll];
    
    UIStackView *buttonStack = [[UIStackView alloc] initForAutoLayout];
    buttonStack.axis = UILayoutConstraintAxisHorizontal;
    buttonStack.spacing = 16.0;
    buttonStack.distribution = UIStackViewDistributionFill;
    buttonStack.directionalLayoutMargins = NSDirectionalEdgeInsetsZero;
    [buttonStack setUserInteractionEnabled:true];
    
    self.pointButton = [MDCFloatingButton floatingButtonWithShape:MDCFloatingButtonShapeMini];
    self.pointButton.accessibilityLabel = @"point";
    [self.pointButton setImage:[UIImage imageNamed:@"observations"] forState:UIControlStateNormal];
    [self.pointButton addTarget:self action:@selector(pointButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    self.lineButton = [MDCFloatingButton floatingButtonWithShape:MDCFloatingButtonShapeMini];
    self.lineButton.accessibilityLabel = @"line";
    [self.lineButton setImage:[UIImage imageNamed:@"line_string"] forState:UIControlStateNormal];
    [self.lineButton addTarget:self action:@selector(lineButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    self.rectangleButton = [MDCFloatingButton floatingButtonWithShape:MDCFloatingButtonShapeMini];
    self.rectangleButton.accessibilityLabel = @"rectangle";
    [self.rectangleButton setImage:[UIImage imageNamed:@"rectangle"] forState:UIControlStateNormal];
    [self.rectangleButton addTarget:self action:@selector(rectangleButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    self.polygonButton = [MDCFloatingButton floatingButtonWithShape:MDCFloatingButtonShapeMini];
    self.polygonButton.accessibilityLabel = @"polygon";
    [self.polygonButton setImage:[UIImage imageNamed:@"polygon"] forState:UIControlStateNormal];
    [self.polygonButton addTarget:self action:@selector(polygonButtonClick:) forControlEvents:UIControlEventTouchUpInside];
    
    [buttonStack addArrangedSubview:self.pointButton];
    [buttonStack addArrangedSubview:self.lineButton];
    [buttonStack addArrangedSubview:self.rectangleButton];
    [buttonStack addArrangedSubview:self.polygonButton];
    
    [self.view addSubview:buttonStack];
    [buttonStack autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.hintView withOffset:16];
    [buttonStack autoPinEdgeToSuperviewEdge:ALEdgeLeft withInset:16];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self buildView];
    
    self.map.delegate = _mapDelegate;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    self.decimalFormatter = [[NSNumberFormatter alloc] init];
    self.decimalFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    self.shapeConverter = [[GPKGMapShapeConverter alloc] init];
    self.validLocation = YES;
    
    [self.latitudeField setDelegate: self];
    [self.longitudeField setDelegate: self];
    [self.mgrsField setDelegate:self];
    [self.garsField setDelegate:self];
    
    [self.latitudeField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.longitudeField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.mgrsField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.garsField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    NSInteger tabIndex = defaults.locationDisplay;
    [self.fieldTypeTabs setSelectedItem:[self.fieldTypeTabs.items objectAtIndex:tabIndex]];
    
    SFGeometry *geometry = [self.coordinator currentGeometry];
    
    if (geometry != nil) {
        [self setShapeTypeFromGeometry:geometry];
        [self addMapShape:geometry];
    
        if (self.shapeType == SF_POINT) {
            SFPoint *centroid = [SFGeometryUtils centroidOfGeometry:geometry];
            MKCoordinateRegion region = MKCoordinateRegionMake(CLLocationCoordinate2DMake([centroid.y doubleValue], [centroid.x doubleValue]), MKCoordinateSpanMake(.03125, .03125));
            MKCoordinateRegion viewRegion = [self.map regionThatFits:region];
            [self.map setRegion:viewRegion animated:NO];
        } else {
            MKCoordinateRegion viewRegion = [self viewRegionOfMapView:self.map forGeometry:geometry];
            [self.map setRegion:viewRegion];
        }
    } else {
        self.shapeType = SF_POINT;
        [self setShapeTypeSelection];
        CLLocation *location = [[LocationService singleton] location];
        if (location) {
            MKCoordinateRegion region = MKCoordinateRegionMake(location.coordinate, MKCoordinateSpanMake(.03125, .03125));
            MKCoordinateRegion viewRegion = [self.map regionThatFits:region];
            [self.map setRegion:viewRegion animated:NO];
        }
    }

    UITapGestureRecognizer * singleTapGesture = [[UITapGestureRecognizer alloc]
                                                 initWithTarget:self action:@selector(singleTapGesture:)];
    singleTapGesture.numberOfTapsRequired = 1;
    [self.map addGestureRecognizer:singleTapGesture];
    UITapGestureRecognizer * doubleTapGesture = [[UITapGestureRecognizer alloc]
                                                 initWithTarget:self action:@selector(doubleTapGesture:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    [self.map addGestureRecognizer:doubleTapGesture];
    [self.map addGestureRecognizer:[[UILongPressGestureRecognizer alloc]
                                    initWithTarget:self action:@selector(longPressGesture:)]];
    [singleTapGesture requireGestureRecognizerToFail:doubleTapGesture];
    
    [self applyThemeWithContainerScheme:self.scheme];
    [self updateHint];
    
    [self setCoordinateTileOverlay:latLngTitle];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.slidescroll setContentOffset:CGPointMake(self.fieldTypeTabs.selectedItem.tag * self.slidescroll.frame.size.width, self.slidescroll.contentOffset.y)];
}

-(void) setCoordinateTileOverlay: (NSString *) coordinateSystem {
    if (coordinateSystem != self.currentCoordinateSystem) {
        MKTileOverlay *tileOverlay = [self coordinateTileOverlay:coordinateSystem];
        if (tileOverlay != nil) {
            self.currentCoordinateSystem = coordinateSystem;
        } else if (self.mapCoordinateSystem != self.currentCoordinateSystem) {
            tileOverlay = [self coordinateTileOverlay:self.mapCoordinateSystem];
            self.currentCoordinateSystem = self.mapCoordinateSystem;
            if (tileOverlay == nil && self.tileOverlay != nil) {
                [self.map removeOverlay:self.tileOverlay];
                self.tileOverlay = nil;
            }
        }
        if (tileOverlay != nil) {
            if (self.tileOverlay != nil) {
                [self.map removeOverlay:self.tileOverlay];
            }
            [self.map addOverlay:tileOverlay];
            self.tileOverlay = tileOverlay;
        }
    }
}

-(MKTileOverlay *) coordinateTileOverlay: (NSString *) coordinateSystem {
    MKTileOverlay *tileOverlay = nil;
    if ([coordinateSystem isEqualToString:mgrsTitle]) {
        tileOverlay = (MKTileOverlay *) [GridSystems mgrsTileOverlay];
    } else if ([coordinateSystem isEqualToString:garsTitle]) {
        tileOverlay = (MKTileOverlay *) [GridSystems garsTileOverlay];
    }
    return tileOverlay;
}

-(MKCoordinateRegion) viewRegionOfMapView: (MKMapView *) mapView forGeometry: (SFGeometry *) geometry {
    GPKGMapShape *shape = [self.shapeConverter toShapeWithGeometry:geometry];
    GPKGBoundingBox *bbox = [shape boundingBox];
    struct GPKGBoundingBoxSize size = [bbox sizeInMeters];
    double expandedHeight = size.height + (2 * (size.height * paddingPercentage));
    double expandedWidth = size.width + (2 * (size.width * paddingPercentage));
    
    CLLocationCoordinate2D center = [bbox center];
    MKCoordinateRegion expandedRegion = MKCoordinateRegionMakeWithDistance(center, expandedHeight, expandedWidth);
    
    double latitudeRange = expandedRegion.span.latitudeDelta / 2.0;
    
    if(expandedRegion.center.latitude + latitudeRange > PROJ_WGS84_HALF_WORLD_LAT_HEIGHT || expandedRegion.center.latitude - latitudeRange < -PROJ_WGS84_HALF_WORLD_LAT_HEIGHT){
        expandedRegion = MKCoordinateRegionMake(mapView.centerCoordinate, MKCoordinateSpanMake(180, 360));
    }
    
    return expandedRegion;
}

- (void) setNavBarSubtitle: (NSString *) subtitle {
    [self.hintLabel setText:subtitle];
    [self.navigationItem setTitle:[self.coordinator fieldName]];
}

- (void) clearLatitudeAndLongitudeFocus{
    [self.latitudeField resignFirstResponder];
    [self.longitudeField resignFirstResponder];
    [self.mgrsField resignFirstResponder];
    [self.dmsLatitudeField resignFirstResponder];
    [self.dmsLongitudeField resignFirstResponder];
    [self.garsField resignFirstResponder];
    [self updateHint];
}

/**
 * Update the hint text
 */
-(void) updateHint{
    [self updateHintWithDragging:NO];
}

/**
 * Update the hint text
 *
 * @param dragging true if a point is currently being dragged
 */
-(void) updateHintWithDragging: (BOOL) dragging{
    
    BOOL locationEdit = self.latitudeField.isEditing || self.longitudeField.isEditing || self.mgrsField.isEditing || self.dmsLatitudeField.isEditing || self.dmsLongitudeField.isEditing || self.garsField.isEditing;
    
    NSString *hint = @"";
    
    switch (self.shapeType) {
        case SF_POINT:
        {
            if (locationEdit) {
                hint = @"Manually modify point coordinates";
            } else {
                if (self.geometry == nil) {
                    hint = @"Long press to set location";
                } else {
                    hint = @"Long press point to modify location";
                }
            }
        }
            break;
        case SF_POLYGON:
        {
            if (self.isRectangle) {
                if (locationEdit) {
                    hint = @"Manually modify corner coordinates";
                } else if (dragging) {
                    hint = @"Drag and release to adjust corner";
                } else if (![self multipleShapePointPositions]) {
                    hint = @"Long press map or point to draw rectangle";
                } else {
                    hint = @"Long press point to adjust corner";
                }
                break;
            }
        }
        case SF_LINESTRING:
            if (locationEdit) {
                hint = @"Manually modify point coordinates";
            } else if (dragging) {
                hint = @"Drag and release to adjust location";
            } else if (self.newDrawing) {
                hint = @"Long press map to add next point";
            } else {
                hint = @"Long press map to insert point between nearest points";
            }
            break;
        default:
            break;
    }
    [self setNavBarSubtitle:hint];
}

/**
 * Update the latitude and longitude text entries
 *
 * @param annotationObservation map annotation observation
 */
- (void) updateLocationTextWithAnnotationObservation: (MapAnnotationObservation *) annotationObservation {
    [self updateLocationTextWithCoordinate:annotationObservation.annotation.coordinate];
}

/**
 * Update the latitude and longitude text entries
 *
 * @param latitude  latitude
 * @param longitude longitude
 */
- (void) updateLocationTextWithLatitude: (double) latitude andLongitude: (double) longitude {
    [self updateLocationTextWithCoordinate:CLLocationCoordinate2DMake(latitude, longitude)];
}

/**
 * Update the latitude and longitude text entries
 *
 * @param coordinate location coordinate
 */
- (void) updateLocationTextWithCoordinate: (CLLocationCoordinate2D) coordinate {
    [self updateLocationTextWithCoordinate:coordinate ignoreSelected:NO];
}

/**
 * Update the latitude and longitude text entries
 *
 * @param coordinate location coordinate
 */
- (void) updateLocationTextWithCoordinate: (CLLocationCoordinate2D) coordinate ignoreSelected: (BOOL) ignore {
    
    if (!ignore || self.fieldTypeTabs.selectedItem.tag != 0) {
        self.latitudeField.text = [NSString stringWithFormat:@"%f", coordinate.latitude];
        self.longitudeField.text = [NSString stringWithFormat:@"%f", coordinate.longitude];
    }
    
    if (!ignore || self.fieldTypeTabs.selectedItem.tag != 1) {
        self.mgrsField.text = [GridSystems mgrs:coordinate];
        [self applyThemeTextField:self.mgrsField];
    }
    
    if (!ignore || self.fieldTypeTabs.selectedItem.tag != 2) {
        self.dmsLatitudeField.text = [LocationUtilities latitudeDMSStringWithCoordinate:coordinate.latitude];
        self.dmsLongitudeField.text = [LocationUtilities longitudeDMSStringWithCoordinate:coordinate.longitude];
    }
    
    if (!ignore || self.fieldTypeTabs.selectedItem.tag != 3) {
        self.garsField.text = [GridSystems gars:coordinate];
        [self applyThemeTextField:self.garsField];
    }
}

- (BOOL) textFieldShouldReturn:(UITextField *) textField {
    [textField resignFirstResponder];
    return NO;
}

- (BOOL)textField:(UITextField *) textField shouldChangeCharactersInRange:(NSRange) range replacementString:(NSString *) string {
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];

    // allow backspace
    if (!string.length) {
        return YES;
    }
    
    if ([@"-" isEqualToString:string] && range.length == 0 && range.location == 0) {
        return YES;
    }
    
    // check for valid lat lng
    CLLocationCoordinate2D coordinate = kCLLocationCoordinate2DInvalid;
    if (textField == self.latitudeField) {
        NSNumber *number = [self.decimalFormatter numberFromString:text];

        if (!number) {
            return NO;
        }
        coordinate = CLLocationCoordinate2DMake([number doubleValue], [self.longitudeField.text doubleValue]);
    } else if (textField == self.longitudeField) {
        NSNumber *number = [self.decimalFormatter numberFromString:text];

        if (!number) {
            return NO;
        }
        coordinate = CLLocationCoordinate2DMake([self.latitudeField.text doubleValue], [number doubleValue]);
    } else if (textField == self.mgrsField) {
        return text.length <= 15;
        // coordinate = [GridSystems mgrsParse:text];
    } else if (textField == self.garsField) {
        return text.length <= 7;
        // coordinate = [GridSystems garsParse:text];
    }
    
    return CLLocationCoordinate2DIsValid(coordinate);
}

- (void)fieldValueChangedWithCoordinate:(CLLocationDegrees)coordinate field:(CoordinateField *)field {
    if (self.fieldTypeTabs.selectedItem.tag == 2) {
        [self onLatLonTextChanged];
    }
}

-(void) textFieldDidChange:(UITextField *) textField {
    if (self.fieldTypeTabs.selectedItem.tag != 2) {
        [self onLatLonTextChanged];
    }
}

- (void) onLatLonTextChanged {
    
    CLLocationCoordinate2D coordinate = kCLLocationCoordinate2DInvalid;
    MDCFilledTextField *themeField = nil;
    
    if (self.fieldTypeTabs.selectedItem.tag == 0) {
        NSDecimalNumber *latitude = nil;
        NSDecimalNumber *longitude = nil;
        NSString *latitudeString = self.latitudeField.text;
        NSString *longitudeString = self.longitudeField.text;
        if(latitudeString.length > 0){
            @try {
                latitude = [[NSDecimalNumber alloc] initWithDouble:[latitudeString doubleValue]];
            } @catch (NSException *exception) {
            }
        }
        if(longitudeString.length > 0){
            @try {
                longitude = [[NSDecimalNumber alloc] initWithDouble:[longitudeString doubleValue]];
            } @catch (NSException *exception) {
            }
        }
        if (latitude != nil && longitude != nil) {
            coordinate = CLLocationCoordinate2DMake([latitude doubleValue], [longitude doubleValue]);
        }

    } else if (self.fieldTypeTabs.selectedItem.tag == 1) {
        coordinate = [GridSystems mgrsParse:self.mgrsField.text];
        themeField = self.mgrsField;
    } else if (self.fieldTypeTabs.selectedItem.tag == 2) {
        coordinate = CLLocationCoordinate2DMake(_dmsLatitudeField.coordinate, _dmsLongitudeField.coordinate);
    } else if (self.fieldTypeTabs.selectedItem.tag == 3) {
        coordinate = [GridSystems garsParse:self.garsField.text];
        themeField = self.garsField;
    }
    
    self.validLocation = CLLocationCoordinate2DIsValid(coordinate);
    
    if (self.validLocation){
        
        if (themeField != nil) {
            [self applyThemeTextField:themeField];
        }
        
        [self.map setCenterCoordinate:coordinate];
        
        if (self.selectedMapPoint != nil) {
            [self.selectedMapPoint setCoordinate:coordinate];
            [self updateShape:coordinate];
        } else if([self.mapObservation isKindOfClass:[MapAnnotationObservation class]]){
            MapAnnotationObservation *mapAnnotationObservation = (MapAnnotationObservation *)self.mapObservation;
            mapAnnotationObservation.annotation.coordinate = coordinate;
            [self updateAcceptState];
        }
        // if it is a point just update the geometry
        if (self.shapeType == SF_POINT) {
            SFPoint *updatedGeometry = [SFPoint pointWithXValue:coordinate.longitude andYValue:coordinate.latitude];
            [self.coordinator updateGeometry:updatedGeometry];
        }
        
        [self updateLocationTextWithCoordinate:coordinate ignoreSelected:YES];
    } else if (themeField != nil) {
        
        [self applyErrorThemeTextField:themeField];
    }
    
}

- (void) mapView: (MKMapView *) mapView didSelectAnnotationView: (MKAnnotationView *) view {
    [self clearLatitudeAndLongitudeFocus];
    [self locationEnabled:YES];
    
    if ([view.annotation isKindOfClass:[GPKGMapPoint class]]) {
        
        GPKGMapPoint *mapPoint = (GPKGMapPoint *) view.annotation;
        view.accessibilityLabel = @"shape_edit";

        if (self.selectedMapPoint == nil || self.selectedMapPoint.id != mapPoint.id) {
            self.lastAnnotationSelectedTime = [NSDate timeIntervalSinceReferenceDate];
            [self selectShapePoint:mapPoint];
        }
    }
}

- (void) mapView: (MKMapView *) mapView didDeselectAnnotationView: (MKAnnotationView *) view {
    if (_shapeType == SF_POINT) {
        return;
    }
    if ([view.annotation isKindOfClass:[GPKGMapPoint class]]) {
        view.accessibilityLabel = @"shape_point";
        view.image.accessibilityLabel = @"shape_point";

        [self locationEnabled:NO];

        GPKGMapPoint *mapPoint = (GPKGMapPoint *) view.annotation;
        if(self.selectedMapPoint != nil && self.selectedMapPoint.id == mapPoint.id){
            MKAnnotationView *view = [self.map viewForAnnotation:self.selectedMapPoint];
            if (self.shapeType != SF_POINT) {
                view.image = [UIImage imageNamed:@"shape_edit"];
            }
            self.selectedMapPoint = nil;
        }
        self.validLocation = YES;
        [self updateAcceptState];
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *) annotationView didChangeDragState:(MKAnnotationViewDragState) newState fromOldState:(MKAnnotationViewDragState) oldState {
   
    if(newState == MKAnnotationViewDragStateStarting){
        [self clearLatitudeAndLongitudeFocus];
    }
    
    CLLocationCoordinate2D coordinate = [self.map convertPoint:annotationView.center toCoordinateFromView:self.map];
    
    if(CLLocationCoordinate2DIsValid(coordinate)){
        switch(newState){
            case MKAnnotationViewDragStateStarting:
                [self annotationViewDragStarting:annotationView withCoordinate:coordinate];
                break;
            case MKAnnotationViewDragStateDragging:
            case MKAnnotationViewDragStateNone:
                [self annotationViewDragging:annotationView withCoordinate:coordinate];
                break;
            case MKAnnotationViewDragStateEnding:
                [self annotationViewDragEnding:annotationView withCoordinate:coordinate];
                break;
            default:
                break;
                
        }
    }
}

- (void) annotationViewDragging: (MKAnnotationView *) annotationView withCoordinate: (CLLocationCoordinate2D) coordinate {
}

- (void) annotationViewDragStarting: (MKAnnotationView *) annotationView withCoordinate: (CLLocationCoordinate2D) coordinate {
    [self updateHintWithDragging:YES];
    if (self.isRectangle && [self isShape]) {
        [[((MapShapePointsObservation *)self.mapObservation) shapePoints] hiddenPoints:YES];
        [self.selectedMapPoint hidden:NO];
    }
}

- (void) annotationViewDragEnding: (MKAnnotationView *) annotationView withCoordinate: (CLLocationCoordinate2D) coordinate {
    [self updateLocationTextWithCoordinate:coordinate];
    [self updateShape:coordinate];
    [self updateHint];
    [self updateGeometry];
    annotationView.dragState = MKAnnotationViewDragStateNone;
}

- (void) updateGeometry {    
    SFGeometry *geometry = nil;
    if (self.geometry != nil) {
        if (self.shapeType == SF_POINT && self.isObservationGeometry) {
            MapAnnotationObservation *mapAnnotationObservation = (MapAnnotationObservation *)self.mapObservation;
            ObservationAnnotation *annotation = mapAnnotationObservation.annotation;
            geometry = [SFPoint pointWithXValue:annotation.coordinate.longitude andYValue:annotation.coordinate.latitude];
        } else {
            @try {
                geometry = [self.shapeConverter toGeometryFromMapShape:[self mapShapePoints].shape];
            }
            @catch (NSException* e) {
                NSLog(@"Invalid Geometry");
            }
        }
    }
    
    [self.coordinator updateGeometry:geometry];
}

- (void)selectAnnotation:(id)annotation{
    [self.map selectAnnotation:annotation animated:YES];
}

- (void) locationEnabled: (BOOL) enabled{
    self.latitudeField.enabled = enabled;
    self.longitudeField.enabled = enabled;
    self.mgrsField.enabled = enabled;
    self.dmsLatitudeField.isEnabled = enabled;
    self.dmsLongitudeField.isEnabled = enabled;
    self.garsField.enabled = enabled;
}

- (void)draggingAnnotationView:(MKAnnotationView *) annotationView atCoordinate: (CLLocationCoordinate2D) coordinate{
    [self updateLocationTextWithCoordinate:coordinate];
    [annotationView.annotation setCoordinate:coordinate];
    [self updateShape:coordinate];
}

-(void) setShapeTypeFromGeometry: (SFGeometry *) geometry{
    _shapeType = geometry.geometryType;
    [self checkIfRectangle:geometry];
    [self setShapeTypeSelection];
}

-(void) checkIfRectangle: (SFGeometry *) geometry{
    _isRectangle = false;
    if(geometry.geometryType == SF_POLYGON){
        SFPolygon *polygon = (SFPolygon *) geometry;
        SFLineString *ring = [polygon ringAtIndex:0];
        NSArray *points = ring.points;
        [self updateIfRectangle: points];
    }
}

-(void) updateIfRectangle: (NSArray *) points{
    NSUInteger size = points.count;
    if(size == 4 || size == 5){
        SFPoint *point1 = [points objectAtIndex:0];
        SFPoint *lastPoint = [points objectAtIndex:size - 1];
        BOOL closed = [point1.x isEqualToNumber:lastPoint.x] && [point1.y isEqualToNumber:lastPoint.y];
        if ((closed && size == 5) || (!closed && size == 4)) {
            SFPoint *point2 = [points objectAtIndex:1];
            SFPoint *point3 = [points objectAtIndex:2];
            SFPoint *point4 = [points objectAtIndex:3];
            if ([point1.x isEqualToNumber:point2.x] && [point2.y isEqualToNumber:point3.y]) {
                if ([point1.y isEqualToNumber:point4.y] && [point3.x isEqualToNumber:point4.x]) {
                    self.isRectangle = true;
                    self.rectangleSameXSide1 = true;
                }
            } else if ([point1.y isEqualToNumber:point2.y] && [point2.x isEqualToNumber:point3.x]) {
                if ([point1.x isEqualToNumber:point4.x] && [point3.y isEqualToNumber:point4.y]) {
                    self.isRectangle = true;
                    self.rectangleSameXSide1 = false;
                }
            }
        }
    }
}

-(void) revertShapeType{
    [self setShapeTypeSelection];
}

- (IBAction)pointButtonClick:(UIButton *)sender {
    [self confirmAndChangeShapeType:SF_POINT andRectangle:NO];
}

- (IBAction)lineButtonClick:(UIButton *)sender {
    [self confirmAndChangeShapeType:SF_LINESTRING andRectangle:NO];
}

- (IBAction)rectangleButtonClick:(UIButton *)sender {
    [self confirmAndChangeShapeType:SF_POLYGON andRectangle:YES];
}

- (IBAction)polygonButtonClick:(UIButton *)sender {
    [self confirmAndChangeShapeType:SF_POLYGON andRectangle:NO];
}

-(void) confirmAndChangeShapeType: (enum SFGeometryType) selectedType andRectangle: (BOOL) selectedRectangle{
    
    // Only care if not the current shape type
    if (selectedType != self.shapeType || selectedRectangle != self.isRectangle) {
        
        [self clearLatitudeAndLongitudeFocus];
        
        NSString *title = nil;
        NSString *message = nil;
        
        // Changing to a point or rectangle, and there are multiple unique positions in the shape
        if ((selectedType == SF_POINT || selectedRectangle) && [self multipleShapePointPositions]) {
            
            if (selectedRectangle) {
                // Changing to a rectangle
                NSArray *points = [self shapePoints];
                BOOL formRectangle = NO;
                if (points.count == 4 || points.count == 5) {
                    NSMutableArray<SFPoint *> *checkPoints = [[NSMutableArray alloc] init];
                    for (GPKGMapPoint *point in points) {
                        [checkPoints addObject:[self.shapeConverter toPointWithMapPoint:point]];
                    }
                    formRectangle = [Observation isRectangleWithPoints:checkPoints];
                }
                if (!formRectangle) {
                    // Points currently do not form a rectangle
                    title = @"Change to Rectangle";
                    message = @"Change to a shape encompassing rectangle?";
                }
                
            } else {
                // Changing to a point
                CLLocationCoordinate2D newPointPosition = [self shapeToPointLocation];
                title = @"Change to Point";
                message = [NSString stringWithFormat:@"Change shape to a single point? %.6f, %.6f", newPointPosition.latitude, newPointPosition.longitude];
            }
            
        }
        
        // If changing to a point and there are multiple points in the current shape, confirm selection
        if (message != nil) {
            
            UIAlertController * alert = [UIAlertController
                                         alertControllerWithTitle:title
                                         message:message
                                         preferredStyle:UIAlertControllerStyleAlert];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                [self revertShapeType];
            }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"Change" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self changeShapeType:selectedType andRectangle:selectedRectangle];
            }]];
            
            [self presentViewController:alert animated:YES completion:nil];
            
        } else {
            [self changeShapeType:selectedType andRectangle:selectedRectangle];
        }
    }
}

-(void) changeShapeType: (enum SFGeometryType) selectedType andRectangle: (BOOL) selectedRectangle{
    
    self.isRectangle = selectedRectangle;
    
    SFGeometry *geometry = nil;
    
    // Changing from point to a shape
    if (self.shapeType == SF_POINT) {
        
        SFLineString *lineString = [SFLineString lineString];
        if (self.geometry != nil) {
            SFPoint *firstPoint = (SFPoint *)self.geometry;
            [lineString addPoint:firstPoint];
            // Changing to a rectangle
            if (selectedRectangle) {
                // Closed rectangle polygon all at the same point
                [lineString addPoint:firstPoint];
                [lineString addPoint:firstPoint];
                [lineString addPoint:firstPoint];
                [lineString addPoint:firstPoint];
            }
        
            // Changing to a line or polygon
            else {
                self.newDrawing = true;
            }
            switch (selectedType) {
                case SF_LINESTRING:
                    geometry = lineString;
                    break;
                case SF_POLYGON:
                    {
                        SFPolygon *polygon = [SFPolygon polygon];
                        [polygon addRing:lineString];
                        geometry = polygon;
                    }
                    break;
                default:
                    [NSException raise:@"Unsupported Geometry" format:@"Unsupported Geometry Type: %u", selectedType];
            }
        }
    }
    // Changing from line or polygon to a point
    else if (selectedType == SF_POINT) {
        if (self.geometry != nil) {
            CLLocationCoordinate2D newPointPosition = [self shapeToPointLocation];
            geometry = [SFPoint pointWithXValue:newPointPosition.longitude andYValue:newPointPosition.latitude];
        }
        self.newDrawing = NO;
    }
    // Changing from between a line, polygon, and rectangle
    else {
        
        SFLineString *lineString = nil;
        if (self.geometry != nil) {
            
            NSArray *points = [self shapePoints];
            
            // If all points are in the same spot only keep one
            if (points.count > 0 && ![self multiplePointPositions:points]) {
                points = [points subarrayWithRange:NSMakeRange(0, 1)];
            }
            
            // Add each point location and find the selected point index
            NSMutableArray<GPKGMapPoint *> *mapPoints = [[NSMutableArray alloc] init];
            NSNumber *startLocation = nil;
            for (GPKGMapPoint *point in points) {
                if (startLocation == nil && self.selectedMapPoint != nil && self.selectedMapPoint.id == point.id) {
                    startLocation = [NSNumber numberWithUnsignedInteger:mapPoints.count];
                }
                [mapPoints addObject:point];
            }
            
            // When going from the polygon or rectangle to a line
            if (selectedType == SF_LINESTRING) {
                // Break the polygon closure when changing to a line
                if (mapPoints.count > 1 && [mapPoints objectAtIndex:0].id == [mapPoints objectAtIndex:mapPoints.count - 1].id) {
                    [mapPoints removeObjectAtIndex:mapPoints.count - 1];
                }
                // Break the line apart at the selected location
                if (startLocation != nil && [startLocation intValue] < mapPoints.count) {
                    NSMutableArray<GPKGMapPoint *> *mapPointsTemp = [[NSMutableArray alloc] init];
                    [mapPointsTemp addObjectsFromArray:[points subarrayWithRange:NSMakeRange([startLocation intValue], mapPoints.count - [startLocation intValue])]];
                    [mapPointsTemp addObjectsFromArray:[points subarrayWithRange:NSMakeRange(0, [startLocation intValue])]];
                    mapPoints = mapPointsTemp;
                }
            }
            
            lineString = [self.shapeConverter toLineStringWithMapPoints:mapPoints];
        }
        
        if (lineString != nil) {
            switch (selectedType) {
                    
                case SF_LINESTRING:
                    {
                        self.newDrawing = [lineString numPoints] <= 1;
                        geometry = lineString;
                    }
                    break;
                    
                case SF_POLYGON:
                    {
                        // If converting to a rectangle, use the current shape bounds
                        if (selectedRectangle) {
                            SFLineString *lineStringCopy = [lineString mutableCopy];
                            [SFGeometryUtils minimizeGeometry:lineStringCopy withMaxX:PROJ_WGS84_HALF_WORLD_LON_WIDTH];
                            SFGeometryEnvelope *envelope = [SFGeometryEnvelopeBuilder buildEnvelopeWithGeometry:lineStringCopy];
                            lineString = [SFLineString lineString];
                            [lineString addPoint:[SFPoint pointWithX:envelope.minX andY:envelope.maxY]];
                            [lineString addPoint:[SFPoint pointWithX:envelope.minX andY:envelope.minY]];
                            [lineString addPoint:[SFPoint pointWithX:envelope.maxX andY:envelope.minY]];
                            [lineString addPoint:[SFPoint pointWithX:envelope.maxX andY:envelope.maxY]];
                            [lineString addPoint:[SFPoint pointWithX:envelope.minX andY:envelope.maxY]];
                            [self updateIfRectangle:lineString.points];
                        }
                        
                        SFPolygon *polygon = [SFPolygon polygon];
                        [polygon addRing:lineString];
                        self.newDrawing = [lineString numPoints] <= 2;
                        geometry = polygon;
                    }
                    break;
                    
                default:
                    [NSException raise:@"Unsupported Geometry" format:@"Unsupported Geometry Type: %u", selectedType];
            }
        }
    }
    
    self.shapeType = selectedType;
    [self setShapeTypeSelection];
    if (geometry != nil) {
        [self addMapShape:geometry];
        [self updateAcceptState];
        
        if (selectedType == SF_POINT) {
            SFPoint *centroidPoint = [SFGeometryUtils centroidOfGeometry:geometry];
            CLLocationCoordinate2D centroidLocation = CLLocationCoordinate2DMake([centroidPoint.y doubleValue], [centroidPoint.x doubleValue]);
            [self.map setCenterCoordinate:centroidLocation animated:YES];
        }
        
        [self updateGeometry];
    }
}

-(CLLocationCoordinate2D) shapeToPointLocation{
    CLLocationCoordinate2D newPointPosition = kCLLocationCoordinate2DInvalid;
    if(self.selectedMapPoint != nil){
        newPointPosition = self.selectedMapPoint.coordinate;
    } else{
        NSString *latitudeString = self.latitudeField.text;
        NSString *longitudeString = self.longitudeField.text;
        double latitude = 0;
        double longitude = 0;
        if (latitudeString.length > 0 && longitudeString.length > 0) {
            latitude = [latitudeString doubleValue];
            longitude = [longitudeString doubleValue];
            newPointPosition = CLLocationCoordinate2DMake(latitude, longitude);
        } else {
            newPointPosition = [self.map convertPoint:self.map.center toCoordinateFromView:self.map];
        }
    }
    return newPointPosition;
}

-(void) addMapShape: (SFGeometry *) geometry{
    self.geometry = geometry;
    CLLocationCoordinate2D previousSelectedPointLocation = kCLLocationCoordinate2DInvalid;
    if(self.selectedMapPoint != nil){
        previousSelectedPointLocation = self.selectedMapPoint.coordinate;
        self.selectedMapPoint = nil;
        [self clearRectangleCorners];
    }
    if(self.mapObservation != nil){
        [self.mapObservation removeFromMapView:self.map];
        self.mapObservation = nil;
    }
    if (geometry.geometryType == SF_POINT) {
        if (self.isObservationGeometry) {
            self.mapObservation = [self.observationManager addToMapWithObservation:self.observation withGeometry:geometry];
            MapAnnotationObservation *mapAnnotationObservation = (MapAnnotationObservation *)self.mapObservation;
            mapAnnotationObservation.annotation.accessibilityLabel = @"point edit annotation";
            [self updateLocationTextWithAnnotationObservation:mapAnnotationObservation];
            [self selectAnnotation:mapAnnotationObservation.annotation];
            
        } else {
            
            GPKGMapShape *shape = [self.shapeConverter toShapeWithGeometry:geometry];
            GPKGMapPointOptions *options = [[GPKGMapPointOptions alloc] init];
            options.image = self.coordinator.pinImage;
            GPKGMapShapePoints *shapePoints = [self.shapeConverter addMapShape:shape asPointsToMapView:self.map withPointOptions:options andPolylinePointOptions:nil andPolygonPointOptions:nil andPolygonPointHoleOptions:nil andPolylineOptions:nil andPolygonOptions:nil];
            self.mapObservation = [[MapShapePointsObservation alloc] initWithObservation:self.observation andShapePoints:shapePoints];
            SFPoint *point = (SFPoint *)geometry;
            [self updateLocationTextWithLatitude:[point.y doubleValue] andLongitude:[point.x doubleValue]];
            shapePoints.shape.shape.accessibilityLabel = @"point edit annotation";
            [self selectAnnotation:shapePoints.shape.shape];
        }
        
    } else {
        GPKGMapShape *shape = [self.shapeConverter toShapeWithGeometry:geometry];
        GPKGMapPointOptions *options = [[GPKGMapPointOptions alloc] init];
        options.image = [UIImage imageNamed:@"shape_edit"];
        GPKGMapShapePoints *shapePoints = [self.shapeConverter addMapShape:shape asPointsToMapView:self.map withPointOptions:options andPolylinePointOptions:[self editPointOptions] andPolygonPointOptions:[self editPointOptions] andPolygonPointHoleOptions:nil andPolylineOptions:nil andPolygonOptions:nil];
        self.mapObservation = [[MapShapePointsObservation alloc] initWithObservation:self.observation andShapePoints:shapePoints];
        NSArray *points = [self shapePoints];
        if (points.count != 0) {
            GPKGMapPoint *selectPoint = [points objectAtIndex:0];
            if(CLLocationCoordinate2DIsValid(previousSelectedPointLocation)){
                for(GPKGMapPoint *point in points){
                    if(point.coordinate.latitude == previousSelectedPointLocation.latitude && point.coordinate.longitude == previousSelectedPointLocation.longitude){
                        selectPoint = point;
                        break;
                    }
                }
            }
            [self selectAnnotation:selectPoint];
        }
    }
    
    [self updateHint];
}


/**
 * Find the neighboring rectangle corners
 *
 * @param point selected point
 */
-(void) findRectangleCorners: (GPKGMapPoint *) point{
    [self clearRectangleCorners];
    if ([self isShape] && self.isRectangle) {
        NSArray* points = [self shapePoints];
        BOOL afterMatchesX = self.rectangleSameXSide1;
        for (int i = 0; i < points.count; i++) {
            GPKGMapPoint *mapPoint = [points objectAtIndex:i];
            if (mapPoint.id == point.id) {
                int beforeIndex = i > 0 ? i - 1 : (int)points.count - 1;
                int afterIndex = i < points.count - 1 ? i + 1 : 0;
                GPKGMapPoint *before = [points objectAtIndex:beforeIndex];
                GPKGMapPoint *after = [points objectAtIndex:afterIndex];
                if (afterMatchesX) {
                    self.rectangleSameXMarker = after;
                    self.rectangleSameYMarker = before;
                } else {
                    self.rectangleSameXMarker = before;
                    self.rectangleSameYMarker = after;
                }
            }
            afterMatchesX = !afterMatchesX;
        }
    }
}

/**
 * Update the neighboring rectangle corners from the modified coordinate
 *
 * @param coordinate modified point coordinate
 */
-(void) updateRectangleCorners: (CLLocationCoordinate2D) coordinate{
    if (self.rectangleSameXMarker != nil) {
        [self.rectangleSameXMarker setCoordinate:CLLocationCoordinate2DMake(self.rectangleSameXMarker.coordinate.latitude, coordinate.longitude)];
    }
    if (self.rectangleSameYMarker != nil) {
        [self.rectangleSameYMarker setCoordinate:CLLocationCoordinate2DMake(coordinate.latitude, self.rectangleSameYMarker.coordinate.longitude)];
    }
}

/**
 * Clear the rectangle corners
 */
-(void) clearRectangleCorners{
    self.rectangleSameXMarker = nil;
    self.rectangleSameYMarker = nil;
}

-(void) singleTapGesture:(UITapGestureRecognizer *) tapGestureRecognizer{
    
    if(tapGestureRecognizer.state == UIGestureRecognizerStateEnded){
        [self clearLatitudeAndLongitudeFocus];
        
        if(self.selectedMapPoint != nil && !self.isRectangle && [self shapePoints].count > 1 && [NSDate timeIntervalSinceReferenceDate] - self.lastAnnotationSelectedTime >= 0.1){
            CGPoint cgPoint = [tapGestureRecognizer locationInView:self.map];
            for (NSObject<MKAnnotation> *annotation in [self.map annotations]) {
                if([annotation isKindOfClass:[GPKGMapPoint class]]){
                    MKAnnotationView* view = [self.map viewForAnnotation:annotation];
                    if(CGRectContainsPoint(view.frame, cgPoint)) {
                        GPKGMapPoint *mapPoint = (GPKGMapPoint *) annotation;
                        if(self.selectedMapPoint.id == mapPoint.id){
                            
                            UIAlertController * alert = [UIAlertController
                                                         alertControllerWithTitle:@"Delete Point"
                                                         message:[NSString stringWithFormat:@"Do you want to delete this point?\n%f, %f", mapPoint.coordinate.latitude, mapPoint.coordinate.longitude]
                                                         preferredStyle:UIAlertControllerStyleAlert];
                            
                            [alert addAction:[UIAlertAction actionWithTitle:@"CANCEL" style:UIAlertActionStyleDefault handler:nil]];
                            
                            [alert addAction:[UIAlertAction actionWithTitle:@"DELETE" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                                NSArray<GPKGMapPoint *> *points = [self shapePoints];
                                
                                // Find the index of the point being deleted
                                int index = 1;
                                for (int i = 0; i < points.count; i++) {
                                    if([points objectAtIndex:i].id == mapPoint.id){
                                        index = i;
                                        break;
                                    }
                                }
                                // Get the previous point index
                                if (index > 0) {
                                    index--;
                                } else if (self.shapeType == SF_LINESTRING) {
                                    // Select next point in the line
                                    index++;
                                } else {
                                    // Select previous polygon point
                                    index = (int)points.count - 1;
                                }
                                // Get the new point to select
                                GPKGMapPoint *selectPoint = [points objectAtIndex:index];
                                
                                // Delete the point, select the new, and update the shape
                                [[self mapShapePoints] deletePoint:mapPoint fromMapView:self.map];
                                self.selectedMapPoint = nil;
                                [self selectAnnotation:selectPoint];
                                [self updateShape:selectPoint.coordinate];
                                [self updateHint];
                            }]];
                            
                            [self presentViewController:alert animated:YES completion:nil];
                            
                            break;
                        }
                    }
                }
            }
        }
    }
}

-(void) doubleTapGesture:(UITapGestureRecognizer *) tapGestureRecognizer{
    
}

-(void) longPressGesture:(UILongPressGestureRecognizer *) longPressGestureRecognizer{
    if(longPressGestureRecognizer.state == UIGestureRecognizerStateBegan){
    
        CGPoint cgPoint = [longPressGestureRecognizer locationInView:self.map];
        CLLocationCoordinate2D point = [self.map convertPoint:cgPoint toCoordinateFromView:self.map];
        
        if (self.shapeType == SF_POINT) {
            SFPoint *geometry = [SFPoint pointWithXValue:point.longitude andYValue:point.latitude];
            [self addMapShape:geometry];
            [self updateGeometry];
        }
        // Add a new point to a line or polygon
        else {
            if (self.isRectangle) {
                if (self.mapObservation == nil) {
                    // brand new rectangle
                    SFGeometry *geometry = nil;
                    
                    SFLineString *lineString = [SFLineString lineString];
                    [lineString addPoint:[SFPoint pointWithXValue:point.longitude andYValue:point.latitude]];
                    [lineString addPoint:[SFPoint pointWithXValue:point.longitude andYValue:point.latitude]];
                    [lineString addPoint:[SFPoint pointWithXValue:point.longitude andYValue:point.latitude]];
                    [lineString addPoint:[SFPoint pointWithXValue:point.longitude andYValue:point.latitude]];
                    [lineString addPoint:[SFPoint pointWithXValue:point.longitude andYValue:point.latitude]];
                    [self updateIfRectangle:lineString.points];
                    
                    SFPolygon *polygon = [SFPolygon polygon];
                    [polygon addRing:lineString];
                    self.newDrawing = [lineString numPoints] <= 2;
                    geometry = polygon;
                    
                    [self addMapShape:geometry];
                    [self setShapeTypeSelection];
                    [self updateAcceptState];
                    [self updateGeometry];
                } else if (![self shapePointsValid] && self.selectedMapPoint != nil) {
                    // Allow long click to expand a zero area rectangle
                    [self.selectedMapPoint setCoordinate:point];
                    [self updateShape:point];
                    [self updateHint];
                    [self updateGeometry];
                }
            }
            else {
                
                if (self.mapObservation == nil) {
                    SFGeometry *geometry = nil;
                    SFPoint *firstPoint = [SFPoint pointWithXValue:point.longitude andYValue:point.latitude];
                    switch (self.shapeType) {
                        case SF_LINESTRING:
                            {
                                SFLineString *lineString = [SFLineString lineString];
                                [lineString addPoint:firstPoint];
                                geometry = lineString;
                            }
                            break;
                        case SF_POLYGON:
                            {
                                SFPolygon *polygon = [SFPolygon polygon];
                                SFLineString *ring = [SFLineString lineString];
                                [ring addPoint:firstPoint];
                                [polygon addRing: ring];
                                geometry = polygon;
                            }
                            break;
                        default:
                            [NSException raise:@"Unsupported Geometry Type" format:@"Unsupported Geometry Type: %u", self.shapeType];
                    }
                    [self addMapShape:geometry];
                    [self updateGeometry];

                } else {
                    GPKGMapPoint *mapPoint = [[GPKGMapPoint alloc] initWithLocation:point];
                    mapPoint.options = [self editPointOptions];
                    [self.map addAnnotation:mapPoint];
                    NSObject<GPKGShapePoints> *shape = nil;
                    GPKGMapShapePoints * mapShapePoints = [self mapShapePoints];
                    GPKGMapShape *mapShape = mapShapePoints.shape;
                    switch(mapShape.shapeType){
                        case GPKG_MST_POLYLINE_POINTS:
                            {
                                GPKGPolylinePoints *polylinePoints = (GPKGPolylinePoints *) mapShape.shape;
                                shape = polylinePoints;
                                if(self.newDrawing){
                                    [polylinePoints addPoint:mapPoint];
                                }else{
                                    [polylinePoints addNewPoint:mapPoint];
                                }
                            }
                            break;
                        case GPKG_MST_POLYGON_POINTS:
                            {
                                GPKGPolygonPoints *polygonPoints = (GPKGPolygonPoints *) mapShape.shape;
                                shape = polygonPoints;
                                if(self.newDrawing){
                                    [polygonPoints addPoint:mapPoint];
                                }else{
                                    [polygonPoints addNewPoint:mapPoint];
                                }
                            }
                            break;
                        default:
                            [NSException raise:@"Unsupported Shape Type" format:@"Unsupported Shape Type: %u", mapShape.shapeType];
                    }
                    [mapShapePoints addPoint:mapPoint withShape:shape];
                    [self selectAnnotation:mapPoint];
                    [self updateShape:mapPoint.coordinate];
                    [self updateGeometry];

                }
            }
        }
    }
    
}

/**
 * Select the provided shape point
 *
 * @param point point to select
 */
-(void) selectShapePoint: (GPKGMapPoint *) point{
    [self clearRectangleCorners];
    self.selectedMapPoint = point;
    [self updateLocationTextWithCoordinate:point.coordinate];
    MKAnnotationView *view = [self.map viewForAnnotation:point];
    if (self.shapeType != SF_POINT) {
        view.image= [UIImage imageNamed:@"shape_edit_selected"];
    }
    [self findRectangleCorners:point];
}

/**
 * Update the shape with any modifications, adjust the accept menu button state
 *
 * @param selectedCoordinate selected coordinate
 */
-(void) updateShape: (CLLocationCoordinate2D) selectedCoordinate {
    [self updateRectangleCorners:selectedCoordinate];
    if ([self isShape]) {
        GPKGMapShapePoints * mapShapePoints = [self mapShapePoints];
        [mapShapePoints updateWithMapView:self.map];
        if ([mapShapePoints isEmpty]) {
            self.mapObservation = nil;
        }
    }
    [self updateAcceptState];
}

- (BOOL) validate:(NSError **) error {
    if (self.shapeType == SF_LINESTRING) {
        if ([[self shapePoints] count] < 2) {
            NSString *domain = @"mil.nga.MAGE.Error";
            NSString *description = @"Lines must contain at least 2 points.";
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : description };
            
            if (error) {
                *error = [NSError errorWithDomain:domain
                                             code:0
                                         userInfo:userInfo];
            }
            
            return NO;
        }
    } else if (self.shapeType == SF_POLYGON) {
        if ([[self shapePoints] count] < 3 || ![self shapePointsValid]) {
            NSString *domain = @"mil.nga.MAGE.Error";
            NSString *description = @"Polygons must contain at least 3 points.";
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : description };
            
            if (error) {
                *error = [NSError errorWithDomain:domain
                                             code:0
                                         userInfo:userInfo];
            }
            
            return NO;
        } else if (!self.allowsPolygonIntersections) {
            SFPolygon *geometry = (SFPolygon *)[self.shapeConverter toGeometryFromMapShape:[self mapShapePoints].shape];
            if ([MapUtils polygonHasIntersections:geometry]) {
                NSString *domain = @"mil.nga.MAGE.Error";
                NSString *description = @"Polygon geometries cannot have self intersections.  Please update the polygon to remove all intersections.";
                NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : description };
                
                if (error) {
                    *error = [NSError errorWithDomain:domain
                                                 code:0
                                             userInfo:userInfo];
                }
                
                return NO;
            }
        }
    }
    
    return YES;
}

/**
 * Update the accept button state
 */
-(void) updateAcceptState{
    BOOL acceptEnabled = NO;
    if (self.shapeType == SF_POINT) {
        // could be in the process of deselecting the shape and changing to a point
        if (![self isShape]) {
            acceptEnabled = YES;
        }
    } else if ([self isShape]) {
        acceptEnabled = [self shapePointsValid];
    }
    acceptEnabled = acceptEnabled && self.validLocation;
    if (acceptEnabled) {
        [self updateGeometry];
    }
}

/**
 * Validate that the shape points are a valid shape and contain multiple unique positions
 *
 * @return true if valid
 */
-(BOOL) shapePointsValid{
    
    return [self multipleShapePointPositions] && [[self mapShapePoints] isValid];
}

/**
 * Determine if there are multiple unique locational positions in the shape points
 *
 * @return true if multiple positions
 */
-(BOOL) multipleShapePointPositions{
    BOOL multiple = NO;
    if ([self isShape]) {
        multiple = [self multiplePointPositions:[self shapePoints]];
    }
    return multiple;
}

/**
 * Determine if the are multiple unique locational positions in the points
 *
 * @param points points
 * @return true if multiple positions
 */
-(BOOL) multiplePointPositions: (NSArray *) points{
    BOOL multiple = NO;
    CLLocationCoordinate2D position = kCLLocationCoordinate2DInvalid;
    for(GPKGMapPoint *point in points){
        if (!CLLocationCoordinate2DIsValid(position)) {
            position = point.coordinate;
        }else if(point.coordinate.latitude != position.latitude || point.coordinate.longitude != position.longitude){
            multiple = true;
            break;
        }
    }
    return multiple;
}

/**
 * Get the shape points
 *
 * @return shape points
 */
-(NSArray *) shapePoints{
    GPKGMapShapePoints * mapShapePoints = [self mapShapePoints];
    if (mapShapePoints.shapePoints.allValues.count != 0) {
        NSObject<GPKGShapePoints> *shapePoints = [mapShapePoints.shapePoints.allValues objectAtIndex:0];
        if (shapePoints != nil && shapePoints != NULL && ![shapePoints isEqual:[NSNull null]]) {
            return [shapePoints points];
        }
    }
    return [[NSArray alloc] init];
}

/**
 * Get the options for an edit point in a shape
 *
 * @return map point options
 */
-(GPKGMapPointOptions *) editPointOptions{
    GPKGMapPointOptions * options = [[GPKGMapPointOptions alloc] init];
    options.draggable = true;
    [options setImage:[UIImage imageNamed:@"shape_edit"]];
    return options;
}

-(BOOL) isShape{
    return self.mapObservation != nil && [self.mapObservation isKindOfClass:[MapShapePointsObservation class]];
}

-(GPKGMapShapePoints *) mapShapePoints{
    MapShapePointsObservation *shapePointsObservation = (MapShapePointsObservation *)self.mapObservation;
    GPKGMapShapePoints * mapShapePoints = [shapePointsObservation shapePoints];
    return mapShapePoints;
}

- (void)tabBarView:(MDCTabBarView *)tabBarView didSelectItem:(UITabBarItem *)item {
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [weakSelf.slidescroll setContentOffset:CGPointMake(item.tag * self.slidescroll.frame.size.width, self.slidescroll.contentOffset.y)];
        } completion:nil];
    });
    [self setCoordinateTileOverlay:item.title];
}

@end

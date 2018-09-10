//
//  GeometryEditViewController.m
//  MAGE
//
//

@import HexColors;

#import "GeometryEditViewController.h"
#import "ObservationAnnotation.h"
#import "ObservationAnnotationView.h"
#import "ObservationImage.h"
#import "LocationService.h"
#import "WKBPoint.h"
#import "GeometryUtility.h"
#import "WKBGeometryUtils.h"
#import "MapObservation.h"
#import "MapObservationManager.h"
#import "GPKGMapShapeConverter.h"
#import "MapShapePointsObservation.h"
#import "MapAnnotationObservation.h"
#import "MapShapePointAnnotationView.h"
#import "GPKGProjectionConstants.h"
#import "WKBGeometryEnvelopeBuilder.h"
#import "Observation.h"
#import "ObservationShapeStyle.h"
#import "Event.h"
#import "GeometryEditMapDelegate.h"
#import "UIColor+UIColor_Mage.h"
#import "UINavigationItem+Subtitle.h"
#import "MapUtils.h"
#import "Theme+UIResponder.h"
#import <mgrs/MGRS.h>
#import <mgrs/mgrs-umbrella.h>

@import SkyFloatingLabelTextField;

static float paddingPercentage = .1;


@interface GeometryEditViewController()<UITextFieldDelegate, EditableMapAnnotationDelegate>

@property (strong, nonatomic) GeometryEditCoordinator *coordinator;
@property (strong, nonatomic) GeometryEditMapDelegate* mapDelegate;
@property (strong, nonatomic) WKBGeometry *geometry;

@property (strong, nonatomic) MapObservation *mapObservation;
@property (strong, nonatomic) MapObservationManager *observationManager;
@property (strong, nonatomic) GPKGMapShapeConverter *shapeConverter;
@property (nonatomic) BOOL newDrawing;
@property (nonatomic) enum WKBGeometryType shapeType;
@property (nonatomic) BOOL isRectangle;
@property (strong, nonatomic) GPKGMapPoint *rectangleSameXMarker;
@property (strong, nonatomic) GPKGMapPoint *rectangleSameYMarker;
@property (nonatomic) BOOL rectangleSameXSide1;
@property (nonatomic) BOOL validLocation;
@property (weak, nonatomic) IBOutlet SkyFloatingLabelTextFieldWithIcon *latitudeField;
@property (weak, nonatomic) IBOutlet SkyFloatingLabelTextFieldWithIcon *longitudeField;
@property (weak, nonatomic) IBOutlet SkyFloatingLabelTextFieldWithIcon *mgrsField;
@property (strong, nonatomic) NSNumberFormatter *decimalFormatter;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (strong, nonatomic) NSTimer *textFieldChangedTimer;
@property (nonatomic) double lastAnnotationSelectedTime;
@property (nonatomic, strong) Observation *observation;
@property (strong, nonatomic) id fieldDefinition;
@property (strong, nonatomic) GPKGMapPoint *selectedMapPoint;
@property (nonatomic) BOOL isObservationGeometry;
@property (weak, nonatomic) IBOutlet UIView *fieldEntryBackground;
@property (weak, nonatomic) IBOutlet UIStackView *fieldStackView;
@property (weak, nonatomic) IBOutlet UISegmentedControl *locationEntryMethod;

@end

@implementation GeometryEditViewController

#define degreesToRadians(x) (M_PI * x / 180.0)
#define radiansToDegrees(x) (x * 180.0 / M_PI)

- (void) themeTextField: (SkyFloatingLabelTextFieldWithIcon *) field {
    field.textColor = [UIColor primaryText];
    field.selectedLineColor = [UIColor brand];
    field.selectedTitleColor = [UIColor brand];
    field.placeholderColor = [UIColor secondaryText];
    field.lineColor = [UIColor secondaryText];
    field.titleColor = [UIColor secondaryText];
    field.errorColor = [UIColor colorWithHexString:@"F44336" alpha:.87];
    field.iconText = @"\U0000f0ac";
    field.iconFont = [UIFont fontWithName:@"FontAwesome" size:15];
}

- (void) themeDidChange:(MageTheme)theme {
    self.view.backgroundColor = [UIColor backgroundColor];
    self.fieldEntryBackground.backgroundColor = [UIColor dialog];
    [UIColor themeMap:self.map];
    [self setShapeTypeSelection];
    [self themeTextField:self.latitudeField];
    [self themeTextField:self.longitudeField];
    [self themeTextField:self.mgrsField];
}

-(void) setShapeTypeSelection {
    [self updateButton:self.pointButton toSelected:self.shapeType == WKB_POINT];
    [self updateButton:self.lineButton toSelected:self.shapeType == WKB_LINESTRING];
    [self updateButton:self.rectangleButton toSelected:self.shapeType == WKB_POLYGON && self.isRectangle];
    [self updateButton:self.polygonButton toSelected:self.shapeType == WKB_POLYGON && !self.isRectangle];
}

- (void) updateButton: (UIButton *) button toSelected: (BOOL) selected {
    if (selected) {
        [button setTintColor:[UIColor activeTabIcon]];
        [button setBackgroundColor:[UIColor dialog]];
    } else {
        [button setTintColor:[UIColor inactiveTabIcon]];
        [button setBackgroundColor:[UIColor dialog]];
    }
}

- (instancetype) initWithCoordinator:(GeometryEditCoordinator *) coordinator {
    if (self = [super init]) {
        _mapDelegate = [[GeometryEditMapDelegate alloc] initWithDragCallback:self andEditDelegate:self];
        _coordinator = coordinator;
    }
    return self;
}

- (IBAction)locationEntryMethodChanged:(id)sender {
    if (self.locationEntryMethod.selectedSegmentIndex == 0) {
        self.mgrsField.hidden = YES;
        self.latitudeField.hidden = NO;
        self.longitudeField.hidden = NO;
    } else {
        self.mgrsField.hidden = NO;
        self.latitudeField.hidden = YES;
        self.longitudeField.hidden = YES;
    }
}

- (void) viewDidLoad {
    [super viewDidLoad];
    self.map.delegate = _mapDelegate;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.map.mapType = [defaults integerForKey:@"mapType"];
    
    self.decimalFormatter = [[NSNumberFormatter alloc] init];
    self.decimalFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    self.shapeConverter = [[GPKGMapShapeConverter alloc] init];
    self.validLocation = YES;
    
    [self.latitudeField setDelegate: self];
    [self.longitudeField setDelegate: self];
    [self.mgrsField setDelegate:self];
    
    [self.latitudeField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.longitudeField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.mgrsField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    if ([defaults boolForKey:@"showMGRS"]) {
        [self.locationEntryMethod setSelectedSegmentIndex:1];
        self.mgrsField.hidden = NO;
        self.latitudeField.hidden = YES;
        self.longitudeField.hidden = YES;
    } else {
        [self.locationEntryMethod setSelectedSegmentIndex:0];
        self.mgrsField.hidden = YES;
        self.latitudeField.hidden = NO;
        self.longitudeField.hidden = NO;
    }
    
    WKBGeometry *geometry = [self.coordinator currentGeometry];
    
    [self setShapeTypeFromGeometry:geometry];
    [self addMapShape:geometry];
    
    if (self.shapeType == WKB_POINT) {
        WKBPoint *centroid = [GeometryUtility centroidOfGeometry:geometry];
        MKCoordinateRegion region = MKCoordinateRegionMake(CLLocationCoordinate2DMake([centroid.y doubleValue], [centroid.x doubleValue]), MKCoordinateSpanMake(.03125, .03125));
        MKCoordinateRegion viewRegion = [self.map regionThatFits:region];
        [self.map setRegion:viewRegion animated:NO];
    } else {
        MKCoordinateRegion viewRegion = [self viewRegionOfMapView:self.map forGeometry:geometry];
        [self.map setRegion:viewRegion];
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
    
    [self registerForThemeChanges];
}

-(MKCoordinateRegion) viewRegionOfMapView: (MKMapView *) mapView forGeometry: (WKBGeometry *) geometry {
    GPKGMapShape *shape = [self.shapeConverter toShapeWithGeometry:geometry];
    GPKGBoundingBox *bbox = [shape boundingBox];
    struct GPKGBoundingBoxSize size = [bbox sizeInMeters];
    double expandedHeight = size.height + (2 * (size.height * paddingPercentage));
    double expandedWidth = size.width + (2 * (size.width * paddingPercentage));
    
    CLLocationCoordinate2D center = [bbox getCenter];
    MKCoordinateRegion expandedRegion = MKCoordinateRegionMakeWithDistance(center, expandedHeight, expandedWidth);
    
    double latitudeRange = expandedRegion.span.latitudeDelta / 2.0;
    
    if(expandedRegion.center.latitude + latitudeRange > PROJ_WGS84_HALF_WORLD_LAT_HEIGHT || expandedRegion.center.latitude - latitudeRange < -PROJ_WGS84_HALF_WORLD_LAT_HEIGHT){
        expandedRegion = MKCoordinateRegionMake(mapView.centerCoordinate, MKCoordinateSpanMake(180, 360));
    }
    
    return expandedRegion;
}

- (void) setNavBarSubtitle: (NSString *) subtitle {
    [self.navigationItem setTitle:[self.coordinator fieldName] subtitle:subtitle];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
}

- (void) keyboardWillShow: (NSNotification *) notification {
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardFrameInViewCoordinates = [self.view convertRect:keyboardFrame fromView:nil];
    self.bottomConstraint.constant = CGRectGetHeight(self.view.bounds) - keyboardFrameInViewCoordinates.origin.y;
    
    [self.view layoutIfNeeded];
    
    [self updateHint];
}

- (void) keyboardWillHide: (NSNotification *) notification {
    self.bottomConstraint.constant = 0;
}

- (void) clearLatitudeAndLongitudeFocus{
    [self.latitudeField resignFirstResponder];
    [self.longitudeField resignFirstResponder];
    [self.mgrsField resignFirstResponder];
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
    
    BOOL locationEdit = self.latitudeField.isEditing || self.longitudeField.isEditing || self.mgrsField.isEditing;
    
    NSString *hint = @"";
    
    switch (self.shapeType) {
        case WKB_POINT:
        {
            if (locationEdit) {
                hint = @"Manually modify point coordinates";
            } else {
                hint = @"Long press point to modify location";
            }
        }
            break;
        case WKB_POLYGON:
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
        case WKB_LINESTRING:
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
 * @param coordinate location coordinate
 */
- (void) updateLocationTextWithCoordinate: (CLLocationCoordinate2D) coordinate {
    [self updateLocationTextWithLatitude:coordinate.latitude andLongitude:coordinate.longitude];
}

/**
 * Update the latitude and longitude text entries
 *
 * @param latitude  latitude
 * @param longitude longitude
 */
- (void) updateLocationTextWithLatitude: (double) latitude andLongitude: (double) longitude {
    [self updateLocationTextWithLatitudeString:[NSString stringWithFormat:@"%f", latitude] andLongitudeString:[NSString stringWithFormat:@"%f", longitude]];
}

/**
 * Update the latitude and longitude text entries
 *
 * @param latitude  latitude
 * @param longitude longitude
 */
- (void) updateLocationTextWithLatitudeString: (NSString *) latitude andLongitudeString: (NSString *) longitude {
    self.latitudeField.text = latitude;
    self.longitudeField.text = longitude;
    self.mgrsField.text = [MGRS MGRSfromCoordinate:CLLocationCoordinate2DMake([latitude doubleValue], [longitude doubleValue])];
}

- (BOOL) textFieldShouldReturn:(UITextField *) textField {
    [textField resignFirstResponder];
    return NO;
}

- (BOOL)textField:(UITextField *) textField shouldChangeCharactersInRange:(NSRange) range replacementString:(NSString *) string {
    
    // allow backspace
    if (!string.length) {
        return YES;
    }
    
    if ([@"-" isEqualToString:string] && range.length == 0 && range.location == 0) {
        return YES;
    }
    
    NSString *text = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSNumber *number = [self.decimalFormatter numberFromString:text];
    
    
    // check for valid lat lng
    CLLocationCoordinate2D coordinate;
    if (textField == self.latitudeField) {
        if (!number) {
            return NO;
        }
        coordinate = CLLocationCoordinate2DMake([number doubleValue], [self.longitudeField.text doubleValue]);
    } else if (textField == self.longitudeField) {
        if (!number) {
            return NO;
        }
        coordinate = CLLocationCoordinate2DMake([self.latitudeField.text doubleValue], [number doubleValue]);
    } else {
        double lat;
        double lon;
        char* mgrs = [text UTF8String];
        Convert_MGRS_To_Geodetic(mgrs, &lat, &lon);
        coordinate = CLLocationCoordinate2DMake(radiansToDegrees(lat), radiansToDegrees(lon));
    }
    
    return CLLocationCoordinate2DIsValid(coordinate);
}

-(void) textFieldDidChange:(UITextField *) textField {
    if (self.textFieldChangedTimer.isValid) {
        [self.textFieldChangedTimer invalidate];
    }
    
    self.textFieldChangedTimer = [NSTimer scheduledTimerWithTimeInterval:.5 target:self selector:@selector(onLatLonTextChanged) userInfo:textField repeats:NO];
}

- (void) onLatLonTextChanged {
    
    NSString *latitudeString = self.latitudeField.text;
    NSString *longitudeString = self.longitudeField.text;
    
    NSDecimalNumber *latitude = nil;
    NSDecimalNumber *longitude = nil;

    if (self.locationEntryMethod.selectedSegmentIndex == 0) {
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
        self.validLocation = latitude != nil && longitude != nil;
        
        if (latitude == nil) {
            latitude = [[NSDecimalNumber alloc] initWithDouble:0.0];
        }
        if (longitude == nil) {
            longitude = [[NSDecimalNumber alloc] initWithDouble:0.0];
        }
    } else {
        double lat;
        double lon;
        const char* mgrs = [self.mgrsField.text UTF8String];
        long error = Convert_MGRS_To_Geodetic(mgrs, &lat, &lon);
        if (lat == 0.0) {
            latitude = [[NSDecimalNumber alloc] initWithDouble:0.0];
        } else {
            latitude = [[NSDecimalNumber alloc] initWithDouble:radiansToDegrees(lat)];
        }
        if (lon == 0.0) {
            longitude = [[NSDecimalNumber alloc] initWithDouble:0.0];
        } else {
            longitude = [[NSDecimalNumber alloc] initWithDouble:radiansToDegrees(lon)];
        }
        
        self.validLocation = error == UTM_NO_ERROR;
    }
    
    if (self.validLocation){
        CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([latitude doubleValue], [longitude doubleValue]);
        
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
        if (self.shapeType == WKB_POINT) {
            WKBPoint *updatedGeometry = [[WKBPoint alloc] initWithXValue:coordinate.longitude andYValue:coordinate.latitude];
            [self.coordinator updateGeometry:updatedGeometry];
        }
    }
    
}

- (void) mapView: (MKMapView *) mapView didSelectAnnotationView: (MKAnnotationView *) view {
    [self clearLatitudeAndLongitudeFocus];
    [self locationEnabled:YES];
    
    if ([view.annotation isKindOfClass:[GPKGMapPoint class]]) {
        
        GPKGMapPoint *mapPoint = (GPKGMapPoint *) view.annotation;
        
        if (self.selectedMapPoint == nil || self.selectedMapPoint.id != mapPoint.id) {
            self.lastAnnotationSelectedTime = [NSDate timeIntervalSinceReferenceDate];
            [self selectShapePoint:mapPoint];
        }
    }
}

- (void) mapView: (MKMapView *) mapView didDeselectAnnotationView: (MKAnnotationView *) view {
    if ([view.annotation isKindOfClass:[GPKGMapPoint class]]) {

        [self locationEnabled:NO];

        GPKGMapPoint *mapPoint = (GPKGMapPoint *) view.annotation;
        if(self.selectedMapPoint != nil && self.selectedMapPoint.id == mapPoint.id){
            MKAnnotationView *view = [self.map viewForAnnotation:self.selectedMapPoint];
            if (self.shapeType != WKB_POINT) {
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
    NSLog(@"Coordinate %f, %f", coordinate.latitude, coordinate.longitude);

    [self updateLocationTextWithCoordinate:coordinate];
    [self updateShape:coordinate];
    [self updateHint];
    [self updateGeometry];
    annotationView.dragState = MKAnnotationViewDragStateNone;
}

- (void) updateGeometry {    
    WKBGeometry *geometry = nil;
    if (self.shapeType == WKB_POINT && self.isObservationGeometry) {
        MapAnnotationObservation *mapAnnotationObservation = (MapAnnotationObservation *)self.mapObservation;
        ObservationAnnotation *annotation = mapAnnotationObservation.annotation;
        geometry = [[WKBPoint alloc] initWithXValue:annotation.coordinate.longitude andYValue:annotation.coordinate.latitude];
    } else {
        @try {
            geometry = [self.shapeConverter toGeometryFromMapShape:[self mapShapePoints].shape];
        }
        @catch (NSException* e) {
            NSLog(@"Invalid Geometry");
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
    self.locationEntryMethod.enabled = enabled;
    UIColor *backgroundColor = nil;
    if(!enabled){
        backgroundColor = [UIColor colorWithHexString:@"DDDDDD"];
    }
    self.latitudeField.backgroundColor = backgroundColor;
    self.longitudeField.backgroundColor = backgroundColor;
    self.mgrsField.backgroundColor = backgroundColor;
}

- (void)draggingAnnotationView:(MKAnnotationView *) annotationView atCoordinate: (CLLocationCoordinate2D) coordinate{
    [self updateLocationTextWithCoordinate:coordinate];
    [annotationView.annotation setCoordinate:coordinate];
    [self updateShape:coordinate];
}

-(void) setShapeTypeFromGeometry: (WKBGeometry *) geometry{
    _shapeType = geometry.geometryType;
    [self checkIfRectangle:geometry];
    [self setShapeTypeSelection];
}

-(void) checkIfRectangle: (WKBGeometry *) geometry{
    _isRectangle = false;
    if(geometry.geometryType == WKB_POLYGON){
        WKBPolygon *polygon = (WKBPolygon *) geometry;
        WKBLineString *ring = [polygon.rings objectAtIndex:0];
        NSArray *points = ring.points;
        [self updateIfRectangle: points];
    }
}

-(void) updateIfRectangle: (NSArray *) points{
    NSUInteger size = points.count;
    if(size == 4 || size == 5){
        WKBPoint *point1 = [points objectAtIndex:0];
        WKBPoint *lastPoint = [points objectAtIndex:size - 1];
        BOOL closed = [point1.x isEqualToNumber:lastPoint.x] && [point1.y isEqualToNumber:lastPoint.y];
        if ((closed && size == 5) || (!closed && size == 4)) {
            WKBPoint *point2 = [points objectAtIndex:1];
            WKBPoint *point3 = [points objectAtIndex:2];
            WKBPoint *point4 = [points objectAtIndex:3];
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
    [self confirmAndChangeShapeType:WKB_POINT andRectangle:NO];
}

- (IBAction)lineButtonClick:(UIButton *)sender {
    [self confirmAndChangeShapeType:WKB_LINESTRING andRectangle:NO];
}

- (IBAction)rectangleButtonClick:(UIButton *)sender {
    [self confirmAndChangeShapeType:WKB_POLYGON andRectangle:YES];
}

- (IBAction)polygonButtonClick:(UIButton *)sender {
    [self confirmAndChangeShapeType:WKB_POLYGON andRectangle:NO];
}

-(void) confirmAndChangeShapeType: (enum WKBGeometryType) selectedType andRectangle: (BOOL) selectedRectangle{
    
    // Only care if not the current shape type
    if (selectedType != self.shapeType || selectedRectangle != self.isRectangle) {
        
        [self clearLatitudeAndLongitudeFocus];
        
        NSString *title = nil;
        NSString *message = nil;
        
        // Changing to a point or rectangle, and there are multiple unique positions in the shape
        if ((selectedType == WKB_POINT || selectedRectangle) && [self multipleShapePointPositions]) {
            
            if (selectedRectangle) {
                // Changing to a rectangle
                NSArray *points = [self shapePoints];
                BOOL formRectangle = NO;
                if (points.count == 4 || points.count == 5) {
                    NSMutableArray<WKBPoint *> *checkPoints = [[NSMutableArray alloc] init];
                    for (GPKGMapPoint *point in points) {
                        [checkPoints addObject:[self.shapeConverter toPointWithMapPoint:point]];
                    }
                    formRectangle = [Observation checkIfRectangle:checkPoints];
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

-(void) changeShapeType: (enum WKBGeometryType) selectedType andRectangle: (BOOL) selectedRectangle{
    
    self.isRectangle = selectedRectangle;
    
    WKBGeometry *geometry = nil;
    
    // Changing from point to a shape
    if (self.shapeType == WKB_POINT) {
        
        WKBPoint *firstPoint = (WKBPoint *)self.coordinator.currentGeometry;
        
//        MapShapePointsObservation *mapAnnotationObservation = (MapShapePointsObservation *)self.mapObservation;
//
//        MapAnnotationObservation *mapAnnotationObservation = (MapAnnotationObservation *)self.mapObservation;
//        ObservationAnnotation *annotation = mapAnnotationObservation.annotation;
//        WKBPoint *firstPoint = [[WKBPoint alloc] initWithXValue:annotation.coordinate.longitude andYValue:annotation.coordinate.latitude];
        WKBLineString *lineString = [[WKBLineString alloc] init];
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
            case WKB_LINESTRING:
                geometry = lineString;
                break;
            case WKB_POLYGON:
                {
                    WKBPolygon *polygon = [[WKBPolygon alloc] init];
                    [polygon addRing:lineString];
                    geometry = polygon;
                }
                break;
            default:
                [NSException raise:@"Unsupported Geometry" format:@"Unsupported Geometry Type: %u", selectedType];
        }
    }
    // Changing from line or polygon to a point
    else if (selectedType == WKB_POINT) {
        CLLocationCoordinate2D newPointPosition = [self shapeToPointLocation];
        geometry = [[WKBPoint alloc] initWithXValue:newPointPosition.longitude andYValue:newPointPosition.latitude];
        self.newDrawing = NO;
    }
    // Changing from between a line, polygon, and rectangle
    else {
        
        WKBLineString *lineString = nil;
        if (self.mapObservation != nil) {
            
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
            if (selectedType == WKB_LINESTRING) {
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
        } else {
            CLLocationCoordinate2D newPointPosition = [self shapeToPointLocation];
            lineString = [[WKBLineString alloc] init];
            [lineString addPoint:[[WKBPoint alloc] initWithXValue:newPointPosition.longitude andYValue:newPointPosition.latitude]];
        }
        
        switch (selectedType) {
                
            case WKB_LINESTRING:
                {
                    self.newDrawing = [[lineString numPoints] intValue] <= 1;
                    geometry = lineString;
                }
                break;
                
            case WKB_POLYGON:
                {
                    // If converting to a rectangle, use the current shape bounds
                    if (selectedRectangle) {
                        WKBLineString *lineStringCopy = [lineString mutableCopy];
                        [WKBGeometryUtils minimizeGeometry:lineStringCopy withMaxX:PROJ_WGS84_HALF_WORLD_LON_WIDTH];
                        WKBGeometryEnvelope *envelope = [WKBGeometryEnvelopeBuilder buildEnvelopeWithGeometry:lineStringCopy];
                        lineString = [[WKBLineString alloc] init];
                        [lineString addPoint:[[WKBPoint alloc] initWithX:envelope.minX andY:envelope.maxY]];
                        [lineString addPoint:[[WKBPoint alloc] initWithX:envelope.minX andY:envelope.minY]];
                        [lineString addPoint:[[WKBPoint alloc] initWithX:envelope.maxX andY:envelope.minY]];
                        [lineString addPoint:[[WKBPoint alloc] initWithX:envelope.maxX andY:envelope.maxY]];
                        [lineString addPoint:[[WKBPoint alloc] initWithX:envelope.minX andY:envelope.maxY]];
                        [self updateIfRectangle:lineString.points];
                    }
                    
                    WKBPolygon *polygon = [[WKBPolygon alloc] init];
                    [polygon addRing:lineString];
                    self.newDrawing = [[lineString numPoints] intValue] <= 2;
                    geometry = polygon;
                }
                break;
                
            default:
                [NSException raise:@"Unsupported Geometry" format:@"Unsupported Geometry Type: %u", selectedType];
        }
    }
    
    self.shapeType = selectedType;
    [self addMapShape:geometry];
    [self setShapeTypeSelection];
    [self updateAcceptState];
    
    if (selectedType == WKB_POINT) {
        WKBPoint *centroidPoint = [WKBGeometryUtils centroidOfGeometry:geometry];
        CLLocationCoordinate2D centroidLocation = CLLocationCoordinate2DMake([centroidPoint.y doubleValue], [centroidPoint.x doubleValue]);
        [self.map setCenterCoordinate:centroidLocation animated:YES];
    }
    
    [self updateGeometry];
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

-(void) addMapShape: (WKBGeometry *) geometry{
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
    if (geometry.geometryType == WKB_POINT) {
        if (self.isObservationGeometry) {
            self.mapObservation = [self.observationManager addToMapWithObservation:self.observation withGeometry:geometry];
            MapAnnotationObservation *mapAnnotationObservation = (MapAnnotationObservation *)self.mapObservation;
            [self updateLocationTextWithAnnotationObservation:mapAnnotationObservation];
            [self selectAnnotation:mapAnnotationObservation.annotation];
            
        } else {
            
            GPKGMapShape *shape = [self.shapeConverter toShapeWithGeometry:geometry];
            GPKGMapPointOptions *options = [[GPKGMapPointOptions alloc] init];
            options.image = self.coordinator.pinImage;
            GPKGMapShapePoints *shapePoints = [self.shapeConverter addMapShape:shape asPointsToMapView:self.map withPointOptions:options andPolylinePointOptions:nil andPolygonPointOptions:nil andPolygonPointHoleOptions:nil];
            self.mapObservation = [[MapShapePointsObservation alloc] initWithObservation:self.observation andShapePoints:shapePoints];
            WKBPoint *point = (WKBPoint *)geometry;
            [self updateLocationTextWithLatitude:[point.y doubleValue] andLongitude:[point.x doubleValue]];
        }
        
    } else {
        GPKGMapShape *shape = [self.shapeConverter toShapeWithGeometry:geometry];
        GPKGMapPointOptions *options = [[GPKGMapPointOptions alloc] init];
        options.image = [UIImage imageNamed:@"shape_edit"];
        GPKGMapShapePoints *shapePoints = [self.shapeConverter addMapShape:shape asPointsToMapView:self.map withPointOptions:options andPolylinePointOptions:[self editPointOptions] andPolygonPointOptions:[self editPointOptions] andPolygonPointHoleOptions:nil];
        self.mapObservation = [[MapShapePointsObservation alloc] initWithObservation:self.observation andShapePoints:shapePoints];
        NSArray *points = [self shapePoints];
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
                                } else if (self.shapeType == WKB_LINESTRING) {
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
        
        // Add a new point to a line or polygon
        if (self.shapeType != WKB_POINT) {
            
            if (!self.isRectangle) {
                
                if (self.mapObservation == nil) {
                    WKBGeometry *geometry = nil;
                    WKBPoint *firstPoint = [[WKBPoint alloc] initWithXValue:point.longitude andYValue:point.latitude];
                    switch (self.shapeType) {
                        case WKB_LINESTRING:
                            {
                                WKBLineString *lineString = [[WKBLineString alloc] init];
                                [lineString addPoint:firstPoint];
                                geometry = lineString;
                            }
                            break;
                        case WKB_POLYGON:
                            {
                                WKBPolygon *polygon = [[WKBPolygon alloc] init];
                                WKBLineString *ring = [[WKBLineString alloc] init];
                                [ring addPoint:firstPoint];
                                [polygon addRing: ring];
                                geometry = polygon;
                            }
                            break;
                        default:
                            [NSException raise:@"Unsupported Geometry Type" format:@"Unsupported Geometry Type: %u", self.shapeType];
                    }
                    [self addMapShape:geometry];
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
                }
            } else if (![self shapePointsValid] && self.selectedMapPoint != nil) {
                // Allow long click to expand a zero area rectangle
                [self.selectedMapPoint setCoordinate:point];
                [self updateShape:point];
                [self updateHint];
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
    if (self.shapeType != WKB_POINT) {
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

- (NSString *) validate {
    NSString *validateMessage = nil;
    
    if (self.shapeType == WKB_LINESTRING) {
        if ([[self shapePoints] count] < 2) {
            validateMessage = @"Lines must contain at least 2 points.";
        }
    } else if (self.shapeType == WKB_POLYGON) {
        if ([[self shapePoints] count] < 3 || ![self shapePointsValid]) {
            validateMessage = @"Polygons must contain at least 3 points.";
        } else if (!self.allowsPolygonIntersections) {
            WKBPolygon *geometry = (WKBPolygon *)[self.shapeConverter toGeometryFromMapShape:[self mapShapePoints].shape];
            
            BOOL hasIntersections = [MapUtils polygonHasIntersections:geometry];
            if (hasIntersections) {
                validateMessage = @"Polygon geometries cannot have self intersections.  Please update the polygon to remove all intersections.";
            }
        }
        
    }
    return validateMessage;
}

/**
 * Update the accept button state
 */
-(void) updateAcceptState{
    BOOL acceptEnabled = NO;
    if (self.shapeType == WKB_POINT) {
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
    NSObject<GPKGShapePoints> *shapePoints = [mapShapePoints.shapePoints.allValues objectAtIndex:0];
    if (shapePoints != nil && shapePoints != NULL && ![shapePoints isEqual:[NSNull null]]) {
        return [shapePoints getPoints];
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

@end

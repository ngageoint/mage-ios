//
//  GeometryEditViewController.m
//  MAGE
//
//

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
#import <HexColor.h>
#import "MapShapePointsObservation.h"
#import "MapAnnotationObservation.h"
#import "MapShapePointAnnotationView.h"
#import "GPKGProjectionConstants.h"
#import "WKBGeometryEnvelopeBuilder.h"
#import "Observation.h"

@interface GeometryEditViewController()<UITextFieldDelegate>
@property (strong, nonatomic) MapObservation *mapObservation;
@property (strong, nonatomic) MapObservationManager *observationManager;
@property (strong, nonatomic) GPKGMapShapeConverter *shapeConverter;
@property (nonatomic) BOOL newDrawing;
@property (nonatomic) enum WKBGeometryType shapeType;
@property (nonatomic) BOOL isRectangle;
@property (strong, nonatomic) GPKGMapPoint *selectedMapPoint;
@property (strong, nonatomic) GPKGMapPoint *rectangleSameXMarker;
@property (strong, nonatomic) GPKGMapPoint *rectangleSameYMarker;
@property (nonatomic) BOOL rectangleSameXSide1;
@property (nonatomic) BOOL validLocation;
@property (weak, nonatomic) IBOutlet UITextField *latitudeField;
@property (weak, nonatomic) IBOutlet UITextField *longitudeField;
@property (strong, nonatomic) NSNumberFormatter *decimalFormatter;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (strong, nonatomic) NSTimer *textFieldChangedTimer;
@property (nonatomic, strong) UIColor * editPolylineColor;
@property (nonatomic) double editPolylineLineWidth;
@property (nonatomic, strong) UIColor * editPolygonColor;
@property (nonatomic) double editPolygonLineWidth;
@property (nonatomic, strong) UIColor * editPolygonFillColor;
@property (nonatomic) double lastAnnotationSelectedTime;

@end

@implementation GeometryEditViewController

static NSString *mapPointImageReuseIdentifier = @"mapPointImageReuseIdentifier";
static NSString *mapPointPinReuseIdentifier = @"mapPointPinReuseIdentifier";

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.decimalFormatter = [[NSNumberFormatter alloc] init];
    self.decimalFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    self.observationManager = [[MapObservationManager alloc] initWithMapView:self.map];
    self.shapeConverter = [[GPKGMapShapeConverter alloc] init];
    self.validLocation = YES;
    
    [self.latitudeField setDelegate: self];
    [self.longitudeField setDelegate: self];
    
    [self.latitudeField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.longitudeField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    
    WKBGeometry *geometry = nil;
    if ([[self.fieldDefinition objectForKey:@"name"] isEqualToString:@"geometry"]) {

        geometry = [self.observation getGeometry];
        if (!geometry) {
            // TODO fixme, bug fix for iOS 10, creating coordinate at 0,0 does not work, create at 1,1
            geometry = [[WKBPoint alloc] initWithXValue:1.0 andYValue:1.0];
        }
        
    } else {
        
        geometry = [self.observation.properties objectForKey:(NSString *)[self.fieldDefinition objectForKey:@"name"]];
        if(!geometry){
            CLLocation *location = [[LocationService singleton] location];
            if(location){
                geometry = [[WKBPoint alloc] initWithXValue:location.coordinate.longitude andYValue:location.coordinate.latitude];
            }else{
                // TODO fixme, bug fix for iOS 10, creating coordinate at 0,0 does not work, create at 1,1
                geometry = [[WKBPoint alloc] initWithXValue:1.0 andYValue:1.0];
            }
        }
    }
    
    // Set the default edit shape draw options
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.editPolylineColor = [UIColor colorWithHexString:[defaults stringForKey:@"edit_polyline_color"] alpha:[defaults integerForKey:@"edit_polyline_color_alpha"] / 255.0];
    self.editPolylineLineWidth = 1.0;
    self.editPolygonColor = [UIColor colorWithHexString:[defaults stringForKey:@"edit_polygon_color"] alpha:[defaults integerForKey:@"edit_polygon_color_alpha"] / 255.0];
    self.editPolygonLineWidth = 1.0;
    self.editPolygonFillColor = [UIColor colorWithHexString:[defaults stringForKey:@"edit_polygon_fill_color"] alpha:[defaults integerForKey:@"edit_polygon_fill_color_alpha"] / 255.0];
    
    [self setShapeTypeFromGeometry:geometry];
    [self addMapShape:geometry];
    
    MKCoordinateRegion viewRegion = [self.mapObservation viewRegionOfMapView:self.map];
    [self.map setRegion:viewRegion];
        
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonPressed)];
    self.navigationItem.leftBarButtonItem = backButton;
    
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

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void) cancelButtonPressed {
    self.navigationItem.prompt = nil;

    [self.navigationController popViewControllerAnimated:YES];
}

- (void) clearLatitudeAndLongitudeFocus{
    [self.latitudeField resignFirstResponder];
    [self.longitudeField resignFirstResponder];
    [self updateHint];
}

- (IBAction) saveLocation {
    self.navigationItem.prompt = nil;
    
    WKBGeometry *geometry = nil;
    if(self.shapeType == WKB_POINT){
        MapAnnotationObservation *mapAnnotationObservation = (MapAnnotationObservation *)self.mapObservation;
        ObservationAnnotation *annotation = mapAnnotationObservation.annotation;
        geometry = [[WKBPoint alloc] initWithXValue:annotation.coordinate.longitude andYValue:annotation.coordinate.latitude];
    }else{
        geometry = [self.shapeConverter toGeometryFromMapShape:[self mapShapePoints].shape];
    }

    [self.propertyEditDelegate setValue:geometry forFieldDefinition:self.fieldDefinition];
    
    [self.navigationController popViewControllerAnimated:YES];
}

- (MKAnnotationView *)mapView:(MKMapView *) mapView viewForAnnotation:(id <MKAnnotation>) annotation {
    
    MKAnnotationView *view = nil;
    
    if ([annotation isKindOfClass:[ObservationAnnotation class]]) {
        ObservationAnnotation *observationAnnotation = annotation;
        MKAnnotationView *annotationView = [observationAnnotation viewForAnnotationOnMapView:self.map withDragCallback:self];
        view = annotationView;
        [observationAnnotation setView:view];
    } else if([annotation isKindOfClass:[GPKGMapPoint class]]){
        GPKGMapPoint * mapPoint = (GPKGMapPoint *) annotation;
        if(mapPoint.options.image != nil){
            MKAnnotationView *mapPointImageView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:mapPointImageReuseIdentifier];
            if (mapPointImageView == nil)
            {
                mapPointImageView = [[MapShapePointAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:mapPointImageReuseIdentifier andMapView:self.map andDragCallback:self];
            }
            mapPointImageView.image = mapPoint.options.image;
            mapPointImageView.centerOffset = mapPoint.options.imageCenterOffset;
            
            view = mapPointImageView;
        }else{
            MKPinAnnotationView *mapPointPinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:mapPointPinReuseIdentifier];
            if(mapPointPinView == nil){
                mapPointPinView = [[MKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:mapPointPinReuseIdentifier];
            }
            mapPointPinView.pinTintColor = mapPoint.options.pinTintColor;
            view = mapPointPinView;
        }
        [mapPoint setView:view];
    }else {
        MKPinAnnotationView *pinView = (MKPinAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:@"pinAnnotation"];
        if (!pinView) {
            pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pinAnnotation"];
            [pinView setPinTintColor:[UIColor greenColor]];
        } else {
            pinView.annotation = annotation;
        }
        view = pinView;
    }
    
    view.draggable = YES;
    return view;
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id)overlay {
    MKOverlayRenderer * renderer = nil;
    if ([overlay isKindOfClass:[MKPolygon class]]) {
        MKPolygonRenderer * polygonRenderer = [[MKPolygonRenderer alloc] initWithPolygon:overlay];
        polygonRenderer.strokeColor = self.editPolygonColor;
        polygonRenderer.lineWidth = self.editPolygonLineWidth;
        if(self.editPolygonFillColor != nil){
            polygonRenderer.fillColor = self.editPolygonFillColor;
        }
        renderer = polygonRenderer;
    }else if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer * polylineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        polylineRenderer.strokeColor = self.editPolylineColor;
        polylineRenderer.lineWidth = self.editPolylineLineWidth;
        renderer = polylineRenderer;
    }else if ([overlay isKindOfClass:[MKTileOverlay class]]) {
        renderer = [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    }
    return renderer;
}

- (void)selectAnnotation:(id)annotation{
    [self.map selectAnnotation:annotation animated:YES];
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view{
    
    [self clearLatitudeAndLongitudeFocus];
    
    if ([view.annotation isKindOfClass:[GPKGMapPoint class]]) {
        
        [self locationEnabled:YES];
        
        GPKGMapPoint *mapPoint = (GPKGMapPoint *) view.annotation;
        
        if (self.selectedMapPoint == nil || self.selectedMapPoint.id != mapPoint.id) {
            self.lastAnnotationSelectedTime = [NSDate timeIntervalSinceReferenceDate];
            [self selectShapePoint:mapPoint];
        }
    }
    
}

- (void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view{
    
    if ([view.annotation isKindOfClass:[GPKGMapPoint class]]) {
        
        [self locationEnabled:NO];
        
        GPKGMapPoint *mapPoint = (GPKGMapPoint *) view.annotation;
        if(self.selectedMapPoint != nil && self.selectedMapPoint.id == mapPoint.id){
            MKAnnotationView *view = [self.map viewForAnnotation:self.selectedMapPoint];
            view.image= [UIImage imageNamed:@"location_tracking_on"]; // TODO Geometry point icons
            self.selectedMapPoint = nil;
        }
        self.validLocation = YES;
        [self updateAcceptState];
    }else if([view.annotation isKindOfClass:[ObservationAnnotation class]]){
        // Reselect the single observation point if it is deselected (clicking on the map, etc)
        [self selectAnnotation:view.annotation];
    }
    
}

- (void) locationEnabled: (BOOL) enabled{
    self.latitudeField.enabled = enabled;
    self.longitudeField.enabled = enabled;
    UIColor *backgroundColor = nil;
    if(!enabled){
        backgroundColor = [UIColor colorWithHexString:@"DDDDDD"];
    }
    self.latitudeField.backgroundColor = backgroundColor;
    self.longitudeField.backgroundColor = backgroundColor;
}

- (void)draggingAnnotationView:(MKAnnotationView *) annotationView atCoordinate: (CLLocationCoordinate2D) coordinate{
    [self updateLocationTextWithCoordinate:coordinate];
    [annotationView.annotation setCoordinate:coordinate];
    [self updateShape:coordinate];
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *) annotationView didChangeDragState:(MKAnnotationViewDragState) newState fromOldState:(MKAnnotationViewDragState) oldState {
    
    if(newState == MKAnnotationViewDragStateStarting){
        [self clearLatitudeAndLongitudeFocus];
    }
    
    CLLocationCoordinate2D coordinate = kCLLocationCoordinate2DInvalid;
    
     if ([annotationView.annotation isKindOfClass:[GPKGMapPoint class]]) {
         coordinate = [self.map convertPoint:annotationView.center toCoordinateFromView:self.map];
     }else if([annotationView.annotation isKindOfClass:[ObservationAnnotation class]]){
         ObservationAnnotation *observationAnnotation = (ObservationAnnotation *) annotationView.annotation;
         coordinate = observationAnnotation.coordinate;
     }
    
    if(CLLocationCoordinate2DIsValid(coordinate)){
        switch(newState){
            case MKAnnotationViewDragStateStarting:
            {
                [self updateHintWithDragging:YES];
                if (self.isRectangle && [self isShape]) {
                    [[((MapShapePointsObservation *)self.mapObservation) shapePoints] hiddenPoints:YES];
                    [self.selectedMapPoint hidden:NO];
                }
            }
                break;
            case MKAnnotationViewDragStateDragging:
            case MKAnnotationViewDragStateNone:
            {
                [self updateLocationTextWithCoordinate:coordinate];
                [annotationView.annotation setCoordinate:coordinate];
                [self updateShape:coordinate];
            }
                break;
            case MKAnnotationViewDragStateEnding:
            {
                [self updateLocationTextWithCoordinate:coordinate];
                [self updateShape:coordinate];
                if (self.isRectangle && [self isShape]) {
                    [[((MapShapePointsObservation *)self.mapObservation) shapePoints] hiddenPoints:NO];
                }
                [self updateHint];
                annotationView.dragState = MKAnnotationViewDragStateNone;
            }
                break;
            default:
                break;
                
        }
    }
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
    if (!number) {
        return NO;
    }
    
    // check for valid lat lng
    CLLocationCoordinate2D coordinate;
    if (textField == self.latitudeField) {
        coordinate = CLLocationCoordinate2DMake([number doubleValue], [self.longitudeField.text doubleValue]);
    } else {
        coordinate = CLLocationCoordinate2DMake([self.latitudeField.text doubleValue], [number doubleValue]);
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
    if(latitudeString.length > 0){
        @try {
            latitude = [[NSDecimalNumber alloc] initWithDouble:[latitudeString doubleValue]];
        } @catch (NSException *exception) {
        }
    }
    NSDecimalNumber *longitude = nil;
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

-(void) setShapeTypeSelection{
    // TODO Geometry
    //pointButton.setSelected(shapeType == GeometryType.POINT);
    //lineButton.setSelected(shapeType == GeometryType.LINESTRING);
    //rectangleButton.setSelected(shapeType == GeometryType.POLYGON && isRectangle);
    //polygonButton.setSelected(shapeType == GeometryType.POLYGON && !isRectangle);
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
            
            [alert addAction:[UIAlertAction actionWithTitle:@"CANCEL" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self revertShapeType];
            }]];
            
            [alert addAction:[UIAlertAction actionWithTitle:@"CHANGE" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
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
        MapAnnotationObservation *mapAnnotationObservation = (MapAnnotationObservation *)self.mapObservation;
        ObservationAnnotation *annotation = mapAnnotationObservation.annotation;
        WKBPoint *firstPoint = [[WKBPoint alloc] initWithXValue:annotation.coordinate.longitude andYValue:annotation.coordinate.latitude];
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
    
    //if (selectedType == WKB_POINT) {
    //    MKCoordinateRegion viewRegion = [self.mapObservation viewRegionOfMapView:self.map];
    //    [self.map setRegion:viewRegion];
    //}
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
    if(geometry.geometryType == WKB_POINT){
        self.mapObservation = [self.observationManager addToMapWithObservation:self.observation withGeometry:geometry];
        MapAnnotationObservation *mapAnnotationObservation = (MapAnnotationObservation *)self.mapObservation;
        [self updateLocationTextWithAnnotationObservation:mapAnnotationObservation];
        [self selectAnnotation:mapAnnotationObservation.annotation];
    }else{
        GPKGMapShape *shape = [self.shapeConverter toShapeWithGeometry:geometry];
        GPKGMapShapePoints *shapePoints = [self.shapeConverter addMapShape:shape asPointsToMapView:self.map withPointOptions:nil andPolylinePointOptions:[self editPointOptions] andPolygonPointOptions:[self editPointOptions] andPolygonPointHoleOptions:nil];
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
    
    BOOL locationEdit = self.latitudeField.isEditing || self.longitudeField.isEditing;
    
    NSString *hint = @"";
    
    switch (self.shapeType) {
        case WKB_POINT:
        {
            if (locationEdit) {
                hint = @"Manually modify point coordinates";
            } else {
                hint = @"Drap map to move point";
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
                    hint = @"Long click map or point to draw rectangle";
                } else {
                    hint = @"Long click point to adjust corner";
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
                hint = @"Long click map to add next point";
            } else {
                hint = @"Long click map to insert point between nearest points";
            }
            break;
        default:
            break;
    }
    
    [self.navigationItem setPrompt:hint];
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
    view.image= [UIImage imageNamed:@"location_tracking_off"]; // TODO Geometry point icons
    [self findRectangleCorners:point];
}

/**
 * Update the shape with any modifications, adjust the accept menu button state
 *
 * @param selectedCoordinate selected coordinate
 */
-(void) updateShape: (CLLocationCoordinate2D) selectedCoordinate{
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

/**
 * Update the accept button state
 */
-(void) updateAcceptState{
    BOOL acceptEnabled = NO;
    if (self.shapeType == WKB_POINT) {
        acceptEnabled = YES;
    } else if ([self isShape]) {
        acceptEnabled = [self shapePointsValid];
    }
    acceptEnabled = acceptEnabled && self.validLocation;
    self.saveButton.enabled = acceptEnabled;
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
    return [shapePoints getPoints];
}

/**
 * Get the options for an edit point in a shape
 *
 * @return map point options
 */
-(GPKGMapPointOptions *) editPointOptions{
    GPKGMapPointOptions * options = [[GPKGMapPointOptions alloc] init];
    options.draggable = true;
    [options setImage:[UIImage imageNamed:@"location_tracking_on"]]; // TODO Geometry point icons
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

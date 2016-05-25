//
//  GeometryEditViewController.m
//  MAGE
//
//

#import "GeometryEditViewController.h"
#import "ObservationAnnotation.h"
#import "ObservationAnnotationView.h"
#import "ObservationImage.h"
#import <GeoPoint.h>

@interface GeometryEditViewController()<UITextFieldDelegate>
@property NSObject<MKAnnotation> *annotation;
@property (weak, nonatomic) IBOutlet UITextField *latitudeField;
@property (weak, nonatomic) IBOutlet UITextField *longitudeField;
@property (strong, nonatomic) NSNumberFormatter *decimalFormatter;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomConstraint;
@property (strong, nonatomic) NSTimer *textFieldChangedTimer;
@end

@implementation GeometryEditViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.decimalFormatter = [[NSNumberFormatter alloc] init];
    self.decimalFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    [self.latitudeField setDelegate: self];
    [self.longitudeField setDelegate: self];
    
    [self.latitudeField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.longitudeField addTarget:self action:@selector(textFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
        
    if (self.geoPoint) {
        CLLocationDistance latitudeMeters = 2500;
        CLLocationDistance longitudeMeters = 2500;
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.geoPoint.location.coordinate, latitudeMeters, longitudeMeters);
        MKCoordinateRegion viewRegion = [self.map regionThatFits:region];
        [self.map setRegion:viewRegion];
    } else {
        self.geoPoint = [[GeoPoint alloc] initWithLocation:[[CLLocation alloc] initWithLatitude:0 longitude:0]];
        self.map.region = MKCoordinateRegionForMapRect(MKMapRectWorld);
    }
    
    if ([[self.fieldDefinition objectForKey:@"name"] isEqualToString:@"geometry"]) {
        GeoPoint *point = (GeoPoint *)[self.observation geometry];
        self.annotation = [[ObservationAnnotation alloc] initWithObservation:self.observation];
        self.annotation.coordinate = point.location.coordinate;
        
    } else {
        GeoPoint *point = (GeoPoint *)[self.observation.properties objectForKey:(NSString *)[self.fieldDefinition objectForKey:@"name"]];
        self.annotation = [[MKPointAnnotation alloc] init];
        self.annotation.coordinate = point.location.coordinate;
    }
    
    [self setLocationTextFields];

    [self.map addAnnotation:self.annotation];
    [self.map selectAnnotation:self.annotation animated:NO];
        
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelButtonPressed)];
    self.navigationItem.leftBarButtonItem = backButton;
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
    
    [self.navigationItem setPrompt:@"Long press marker and drag to a new location."];
}

- (void) cancelButtonPressed {
    self.navigationItem.prompt = nil;

    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction) saveLocation {
    self.navigationItem.prompt = nil;
    self.geoPoint.location = [[CLLocation alloc] initWithLatitude:self.annotation.coordinate.latitude longitude:self.annotation.coordinate.longitude];
    
    [self performSegueWithIdentifier:@"unwindToEditController" sender:self];
}

- (MKAnnotationView *)mapView:(MKMapView *) mapView viewForAnnotation:(id <MKAnnotation>) annotation {
    
    if ([annotation isKindOfClass:[ObservationAnnotation class]]) {
        ObservationAnnotation *observationAnnotation = annotation;
        UIImage *image = [ObservationImage imageForObservation:observationAnnotation.observation inMapView:mapView];
        MKAnnotationView *annotationView = (MKAnnotationView *) [self.map dequeueReusableAnnotationViewWithIdentifier:[image accessibilityIdentifier]];
        
        if (annotationView == nil) {
            annotationView = [[ObservationAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:[image accessibilityIdentifier]];
            annotationView.draggable = YES;
            annotationView.image = image;
        } else {
            annotationView.annotation = annotation;
        }
        annotationView.centerOffset = CGPointMake(0, -(annotationView.image.size.height/2.0f));
        return annotationView;
    } else {
        MKPinAnnotationView *pinView = (MKPinAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:@"pinAnnotation"];
        
        if (!pinView) {
            pinView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"pinAnnotation"];
            [pinView setPinColor:MKPinAnnotationColorGreen];
            pinView.draggable = YES;
        } else {
            pinView.annotation = annotation;
        }
        
        return pinView;
    }
    
    return nil;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    if (newState == MKAnnotationViewDragStateEnding) {
        [self setLocationTextFields];
    }
}

- (void) setLocationTextFields {
    self.latitudeField.text = [NSString stringWithFormat:@"%f", self.annotation.coordinate.latitude];
    self.longitudeField.text = [NSString stringWithFormat:@"%f", self.annotation.coordinate.longitude];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    
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
    self.annotation.coordinate = CLLocationCoordinate2DMake([self.latitudeField.text doubleValue], [self.longitudeField.text doubleValue]);
    
    CLLocationDistance latitudeMeters = 2500;
    CLLocationDistance longitudeMeters = 2500;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.annotation.coordinate, latitudeMeters, longitudeMeters);
    [self.map setRegion:region animated:NO];
}

- (void) keyboardWillShow: (NSNotification *) notification {
    CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect keyboardFrameInViewCoordinates = [self.view convertRect:keyboardFrame fromView:nil];
    self.bottomConstraint.constant = CGRectGetHeight(self.view.bounds) - keyboardFrameInViewCoordinates.origin.y;
    
    [self.view layoutIfNeeded];
}

- (void) keyboardWillHide: (NSNotification *) notification {
    self.bottomConstraint.constant = 0;
}



@end

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

@interface GeometryEditViewController()
@property NSObject<MKAnnotation> *annotation;
@end

@implementation GeometryEditViewController

- (IBAction) saveLocation {
//    GeoPoint *point = self.observation.geometry;
//    point.location = [[CLLocation alloc] initWithLatitude:self.annotation.coordinate.latitude longitude:self.annotation.coordinate.longitude];
//    
//    
//    [self setGeoPoint:point];
    [self performSegueWithIdentifier:@"unwindToEditController" sender:self];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
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
    
    [self.map addAnnotation:self.annotation];
    [self.map selectAnnotation:self.annotation animated:NO];
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

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState
{
    if (newState == MKAnnotationViewDragStateEnding) {
        self.geoPoint.location = [[CLLocation alloc] initWithLatitude:annotationView.annotation.coordinate.latitude longitude:annotationView.annotation.coordinate.longitude];
    }
}

@end

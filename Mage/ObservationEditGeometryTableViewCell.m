//
//  ObservationEditGeometryTableViewCell.m
//  MAGE
//
//

#import "ObservationEditGeometryTableViewCell.h"
#import <CoreLocation/CoreLocation.h>
#import "Observation.h"
#import "MapDelegate.h"
#import "ObservationAnnotation.h"
#import "GeometryUtility.h"
#import "MapObservationManager.h"
#import "MapAnnotationObservation.h"
#import <Event.h>

@interface ObservationEditGeometryTableViewCell()

@property (strong, nonatomic) MapDelegate *mapDelegate;
@property (strong, nonatomic) MapObservation *mapObservation;
@property (strong, nonatomic) MapObservationManager *observationManager;
@property (assign, nonatomic) BOOL isGeometryField;

@end

@implementation ObservationEditGeometryTableViewCell

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    
    // special case if it is the actual observation geometry and not a field
    if ([[field objectForKey:@"name"] isEqualToString:@"geometry"]) {
        self.geometry = [observation getGeometry];
        self.isGeometryField = YES;
    } else {
        id geometry = [observation.properties objectForKey:[field objectForKey:@"name"]];
        if (geometry) {
            self.geometry = (WKBGeometry *) geometry;
        } else {
            self.geometry = nil;
        }
        self.isGeometryField = NO;
    }

    [self.keyLabel setText:[field objectForKey:@"title"]];
    [self.requiredIndicator setHidden: ![[field objectForKey: @"required"] boolValue]];
    
    self.mapDelegate = [[MapDelegate alloc] init];
    Event *event = [Event getCurrentEventInContext:observation.managedObjectContext];
    NSArray *forms = event.forms;

    [self.mapDelegate setMapView: self.mapView];
    self.mapView.delegate = self.mapDelegate;
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
    
    self.mapDelegate.hideStaticLayers = YES;
    
    if (self.geometry) {
        self.observationManager = [[MapObservationManager alloc] initWithMapView:self.mapView andEventForms:forms];
        if (self.isGeometryField) {
            self.mapObservation = [self.observationManager addToMapWithObservation:observation];
            MKCoordinateRegion viewRegion = [self.mapObservation viewRegionOfMapView:self.mapView];
            [self.mapView setRegion:viewRegion animated:NO];
        }
        
        WKBPoint *point = [GeometryUtility centroidOfGeometry:self.geometry];
        [self.latitude setText:[NSString stringWithFormat:@"%.6f", [point.y doubleValue]]];
        [self.longitude setText:[NSString stringWithFormat:@"%.6f", [point.x doubleValue]]];

        if (!self.isGeometryField) {
            MKPointAnnotation *annotation = [[MKPointAnnotation alloc] init];
            annotation.coordinate = CLLocationCoordinate2DMake([point.y doubleValue], [point.x doubleValue]);
            [self.mapView addAnnotation:annotation];
            MKCoordinateRegion region = MKCoordinateRegionMake(annotation.coordinate, MKCoordinateSpanMake(.03125, .03125));
            MKCoordinateRegion viewRegion = [self.mapView regionThatFits:region];
            [self.mapView setRegion:viewRegion animated:NO];
        }
            
    } else {
        [self.mapView removeAnnotations:self.mapView.annotations];
        self.mapView.region = MKCoordinateRegionForMapRect(MKMapRectWorld);
        
        [self.latitude setText:@""];
        [self.longitude setText:@""];
    }
}

- (BOOL) isEmpty {
    return self.geometry == nil;
}

- (void) setValid:(BOOL) valid {
    [super setValid:valid];
    
    if (valid) {
        self.latitudeLabel.textColor = nil;
        self.longitudeLabel.textColor = nil;
    } else {
        self.latitudeLabel.textColor = [UIColor redColor];
        self.longitudeLabel.textColor = [UIColor redColor];
    }
}

- (void) typeChanged:(Observation *) observation {
    if (self.isGeometryField) {
        [self.mapObservation removeFromMapView:self.mapView];
        self.mapObservation = [self.observationManager addToMapWithObservation:observation];
    }
}

- (void) variantChanged:(Observation *)observation {
    if (self.isGeometryField) {
        [self.mapObservation removeFromMapView:self.mapView];
        self.mapObservation = [self.observationManager addToMapWithObservation:observation];
    }
}

@end

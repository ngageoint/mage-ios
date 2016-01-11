//
//  ObservationEditGeometryTableViewCell.m
//  MAGE
//
//

#import "ObservationEditGeometryTableViewCell.h"
#import <CoreLocation/CoreLocation.h>
#import "Observation+helper.h"
#import "MapDelegate.h"

@interface ObservationEditGeometryTableViewCell()

@property (strong, nonatomic) MapDelegate *mapDelegate;
@property (strong, nonatomic) MKPointAnnotation *annotation;

@end

@implementation ObservationEditGeometryTableViewCell

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    
    // special case if it is the actual observation geometry and not a field
    if ([[field objectForKey:@"name"] isEqualToString:@"geometry"]) {
        self.geoPoint = (GeoPoint *)[observation geometry];
    } else {
        id geometry = [observation.properties objectForKey:[field objectForKey:@"name"]];
        if (geometry) {
            self.geoPoint = (GeoPoint *) geometry;
        } else {
            self.geoPoint = nil;
        }
    }

    [self.keyLabel setText:[field objectForKey:@"title"]];
    [self.requiredIndicator setHidden: ![[field objectForKey: @"required"] boolValue]];
    
    self.mapDelegate = [[MapDelegate alloc] init];
    [self.mapDelegate setMapView: self.mapView];
    self.mapView.delegate = self.mapDelegate;
    
    self.mapDelegate.hideStaticLayers = YES;
    
    if (self.geoPoint) {
        [self.latitude setText:[NSString stringWithFormat:@"%.6f",self.geoPoint.location.coordinate.latitude]];
        [self.longitude setText:[NSString stringWithFormat:@"%.6f",self.geoPoint.location.coordinate.longitude]];
        
        CLLocationDistance latitudeMeters = 2500;
        CLLocationDistance longitudeMeters = 2500;
        MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.geoPoint.location.coordinate, latitudeMeters, longitudeMeters);
        MKCoordinateRegion viewRegion = [self.mapView regionThatFits:region];
        [self.mapView setRegion:viewRegion animated:NO];
        
        self.annotation = [[MKPointAnnotation alloc] init];
        self.annotation.coordinate = self.geoPoint.location.coordinate;
        [self.mapView addAnnotation:self.annotation];
    } else {
        [self.mapView removeAnnotations:self.mapView.annotations];
        self.mapView.region = MKCoordinateRegionForMapRect(MKMapRectWorld);
        
        [self.latitude setText:@""];
        [self.longitude setText:@""];
    }
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
};

@end

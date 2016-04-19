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

@interface ObservationEditGeometryTableViewCell()

@property (strong, nonatomic) MapDelegate *mapDelegate;
@property (strong, nonatomic) id<MKAnnotation> annotation;
@property (assign, nonatomic) BOOL isGeometryField;

@end

@implementation ObservationEditGeometryTableViewCell

- (void) populateCellWithFormField: (id) field andObservation: (Observation *) observation {
    
    // special case if it is the actual observation geometry and not a field
    if ([[field objectForKey:@"name"] isEqualToString:@"geometry"]) {
        self.geoPoint = (GeoPoint *)[observation geometry];
        self.isGeometryField = YES;
    } else {
        id geometry = [observation.properties objectForKey:[field objectForKey:@"name"]];
        if (geometry) {
            self.geoPoint = (GeoPoint *) geometry;
        } else {
            self.geoPoint = nil;
        }
        self.isGeometryField = NO;
    }

    [self.keyLabel setText:[field objectForKey:@"title"]];
    [self.requiredIndicator setHidden: ![[field objectForKey: @"required"] boolValue]];
    
    self.mapDelegate = [[MapDelegate alloc] init];
    [self.mapDelegate setMapView: self.mapView];
    self.mapView.delegate = self.mapDelegate;
    [self.mapView removeAnnotations:self.mapView.annotations];
    
    self.mapDelegate.hideStaticLayers = YES;
    
    if (self.geoPoint) {
        [self.latitude setText:[NSString stringWithFormat:@"%.6f", self.geoPoint.location.coordinate.latitude]];
        [self.longitude setText:[NSString stringWithFormat:@"%.6f", self.geoPoint.location.coordinate.longitude]];

        if (self.isGeometryField) {
            self.annotation = [[ObservationAnnotation alloc] initWithObservation:observation];
        } else {
            self.annotation = [[MKPointAnnotation alloc] init];
        }
        
        self.annotation.coordinate = self.geoPoint.location.coordinate;
        [self.mapView addAnnotation:self.annotation];
        
        MKCoordinateRegion region = MKCoordinateRegionMake(self.annotation.coordinate, MKCoordinateSpanMake(.03125, .03125));
        MKCoordinateRegion viewRegion = [self.mapView regionThatFits:region];
        [self.mapView setRegion:viewRegion animated:NO];
    } else {
        [self.mapView removeAnnotations:self.mapView.annotations];
        self.mapView.region = MKCoordinateRegionForMapRect(MKMapRectWorld);
        
        [self.latitude setText:@""];
        [self.longitude setText:@""];
    }
}

- (BOOL) isEmpty {
    return self.geoPoint == nil;
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
        [self.mapView removeAnnotation:self.annotation];
        self.annotation = [[ObservationAnnotation alloc] initWithObservation:observation];
        [self.mapView addAnnotation:self.annotation];
    }
}

- (void) variantChanged:(Observation *)observation {
    if (self.isGeometryField) {
        [self.mapView removeAnnotation:self.annotation];
        self.annotation = [[ObservationAnnotation alloc] initWithObservation:observation];
        [self.mapView addAnnotation:self.annotation];
    }
}

@end

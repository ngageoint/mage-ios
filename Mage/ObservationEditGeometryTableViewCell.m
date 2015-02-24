//
//  ObservationEditGeometryTableViewCell.m
//  MAGE
//
//  Created by Dan Barela on 9/25/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
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
    
    // special case if it is the actuial observation geometry and not a field
    if ([[field objectForKey:@"name"] isEqualToString:@"geometry"]) {
        self.geoPoint = (GeoPoint *)[observation geometry];
    } else {
        self.geoPoint = (GeoPoint *)[observation.properties objectForKey:(NSString *)[field objectForKey:@"name"]];
    }

    [self.latitude setText:[NSString stringWithFormat:@"%.6f",self.geoPoint.location.coordinate.latitude]];
    [self.longitude setText:[NSString stringWithFormat:@"%.6f",self.geoPoint.location.coordinate.longitude]];
    [self.keyLabel setText:[field objectForKey:@"title"]];
    [self.requiredIndicator setHidden: ![[field objectForKey: @"required"] boolValue]];
    

    self.mapDelegate = [[MapDelegate alloc] init];
    [self.mapDelegate setMapView: self.mapView];
    self.mapView.delegate = self.mapDelegate;
    
    self.mapDelegate.hideStaticLayers = YES;
    
    CLLocationDistance latitudeMeters = 2500;
    CLLocationDistance longitudeMeters = 2500;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.geoPoint.location.coordinate, latitudeMeters, longitudeMeters);
    MKCoordinateRegion viewRegion = [self.mapView regionThatFits:region];
    [self.mapView setRegion:viewRegion animated:NO];
    
    self.annotation = [[MKPointAnnotation alloc] init];
    self.annotation.coordinate = self.geoPoint.location.coordinate;
    [self.mapView addAnnotation:self.annotation];
}

@end

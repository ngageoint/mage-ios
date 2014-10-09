//
//  GeometryEditViewController.m
//  MAGE
//
//  Created by Dan Barela on 10/7/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "GeometryEditViewController.h"
#import "ObservationAnnotation.h"
#import "ObservationImage.h"
#import <GeoPoint.h>

@interface GeometryEditViewController()
@property ObservationAnnotation *annotation;
@end

@implementation GeometryEditViewController

- (id) init {
    
    return self;
}

- (IBAction) saveLocation {
    GeoPoint *point = self.observation.geometry;
    point.location = [[CLLocation alloc] initWithLatitude:self.annotation.coordinate.latitude longitude:self.annotation.coordinate.longitude];
    [self setGeoPoint:point];
    [self performSegueWithIdentifier:@"unwindToEditController" sender:self];
}

- (void) viewDidLoad {
    CLLocationDistance latitudeMeters = 500;
    CLLocationDistance longitudeMeters = 500;
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.geoPoint.location.coordinate, latitudeMeters, longitudeMeters);
    MKCoordinateRegion viewRegion = [self.map regionThatFits:region];
    [self.map setRegion:viewRegion];
    
    self.annotation = [[ObservationAnnotation alloc] initWithObservation:self.observation];
    
    if ([[self.fieldDefinition objectForKey:@"name"] isEqualToString:@"geometry"]) {
        GeoPoint *point = (GeoPoint *)[self.observation geometry];
        self.annotation.coordinate = point.location.coordinate;
    } else {
        GeoPoint *point = (GeoPoint *)[self.observation.properties objectForKey:(NSString *)[self.fieldDefinition objectForKey:@"name"]];
        self.annotation.coordinate = point.location.coordinate;
    }
    
    [self.map addAnnotation:self.annotation];
}

- (MKAnnotationView *)mapView:(MKMapView *) mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    
    if ([annotation isKindOfClass:[ObservationAnnotation class]]) {
        ObservationAnnotation *observationAnnotation = annotation;
        UIImage *image = [ObservationImage imageForObservation:observationAnnotation.observation scaledToWidth:[NSNumber numberWithFloat:35]];
        MKAnnotationView *annotationView = (MKAnnotationView *) [self.map dequeueReusableAnnotationViewWithIdentifier:[image accessibilityIdentifier]];
        
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:[image accessibilityIdentifier]];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
            annotationView.draggable = YES;
            if (image == nil) {
                annotationView.image = [self imageWithImage:[UIImage imageNamed:@"defaultMarker"] scaledToWidth:35];
            } else {
                annotationView.image = image;
            }
        } else {
            annotationView.annotation = annotation;
        }
        annotationView.centerOffset = CGPointMake(0, -(annotationView.image.size.height/2.0f));
        return annotationView;
    }
    
    return nil;
}

-(UIImage*)imageWithImage: (UIImage*) sourceImage scaledToWidth: (float) i_width
{
    float oldWidth = sourceImage.size.width;
    float scaleFactor = i_width / oldWidth;
    
    float newHeight = sourceImage.size.height * scaleFactor;
    float newWidth = oldWidth * scaleFactor;
    
    UIGraphicsBeginImageContext(CGSizeMake(newWidth, newHeight));
    [sourceImage drawInRect:CGRectMake(0, 0, newWidth, newHeight)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end

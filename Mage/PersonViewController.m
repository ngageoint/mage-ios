//
//  PersonViewController.m
//  Mage
//
//  Created by Billy Newman on 7/17/14.
//

#import "PersonViewController.h"

#import "LocationAnnotation.h"
#import "User+helper.h"
#import "PersonImage.h"
#import "GeoPoint.h"

@implementation PersonViewController

- (void) viewDidLoad {
    [super viewDidLoad];
	
	NSString *name = _location.user.name.length ? _location.user.name : _location.user.username;
	self.navigationItem.title = name;
	
	[_mapView setDelegate:self];
	CLLocationDistance latitudeMeters = 500;
	CLLocationDistance longitudeMeters = 500;
	GeoPoint *point = _location.geometry;
	NSDictionary *properties = _location.properties;
	id accuracyProperty = [properties valueForKeyPath:@"accuracy"];
	if (accuracyProperty != nil) {
		double accuracy = [accuracyProperty doubleValue];
		latitudeMeters = accuracy > latitudeMeters ? accuracy * 2.5 : latitudeMeters;
		longitudeMeters = accuracy > longitudeMeters ? accuracy * 2.5 : longitudeMeters;
		
		MKCircle *circle = [MKCircle circleWithCenterCoordinate:point.location.coordinate radius:accuracy];
		[_mapView addOverlay:circle];
	}
	
	MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(point.location.coordinate, latitudeMeters, longitudeMeters);
	MKCoordinateRegion viewRegion = [self.mapView regionThatFits:region];
	[_mapView setRegion:viewRegion];
	
	LocationAnnotation *annotation = [[LocationAnnotation alloc] initWithLocation:_location];
	[_mapView addAnnotation:annotation];
}

- (MKAnnotationView *)mapView:(MKMapView *) mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	
    if ([annotation isKindOfClass:[LocationAnnotation class]]) {
		LocationAnnotation *locationAnnotation = annotation;
		NSString *imageName = [PersonImage imageNameForTimestamp:locationAnnotation.timestamp];
        MKAnnotationView *annotationView = (MKAnnotationView *) [_mapView dequeueReusableAnnotationViewWithIdentifier:imageName];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:imageName];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
            annotationView.image = [UIImage imageNamed:imageName];
		} else {
            annotationView.annotation = annotation;
        }
		
        return annotationView;
    }
	
    return nil;
}

- (MKOverlayRenderer *) mapView:(MKMapView *) mapView rendererForOverlay:(id < MKOverlay >) overlay {
	MKCircleRenderer *renderer = [[MKCircleRenderer alloc] initWithCircle:overlay];
	renderer.lineWidth = 1.0f;
	
	NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:_location.timestamp];
	if (interval <= 600) {
		renderer.fillColor = [UIColor colorWithRed:0 green:0 blue:1 alpha:.1f];
		renderer.strokeColor = [UIColor blueColor];
	} else if (interval <= 1200) {
		renderer.fillColor = [UIColor colorWithRed:1 green:1 blue:0 alpha:.1f];
		renderer.strokeColor = [UIColor yellowColor];
	} else {
		renderer.fillColor = [UIColor colorWithRed:1 green:.5 blue:0 alpha:.1f];
		renderer.strokeColor = [UIColor orangeColor];
	}
	
	return renderer;
}


@end

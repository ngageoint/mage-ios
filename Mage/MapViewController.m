//
//  MapViewController.m
//  Mage
//
//  Created by Dan Barela on 4/29/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "MapViewController.h"

#import "AppDelegate.h"
#import "Geometry.h"
#import "GeoPoint.h"
#import "PersonImage.h"
#import "User+helper.h"
#import "Location+helper.h"
#import "LocationAnnotation.h"
#import "ObservationAnnotation.h"
#import "Observation.h"
#import "ObservationImage.h"
#import "PersonViewController.h"
#import "ObservationViewController.h"
#import <MapKit/MapKit.h>

@interface MapViewController ()
	@property (nonatomic) NSMutableDictionary *locationAnnotations;
    @property (nonatomic) NSMutableDictionary *observationAnnotations;
@end

@implementation MapViewController

- (NSFetchedResultsController *) observationResultsController {
	
	if (_observationResultsController != nil) {
		return _observationResultsController;
	}
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Observation" inManagedObjectContext:_managedObjectContext]];
    // TODO look at this, I think we changed Android to timestamp or something
	[fetchRequest setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"lastModified" ascending:NO]]];
    
	_observationResultsController = [[NSFetchedResultsController alloc]
								  initWithFetchRequest:fetchRequest
								  managedObjectContext:_managedObjectContext
								  sectionNameKeyPath:nil
								  cacheName:nil];
    
	[_observationResultsController setDelegate:self];
	
	return _observationResultsController;
}

- (NSFetchedResultsController *) locationResultsController {
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:[NSEntityDescription entityForName:@"Location" inManagedObjectContext:_managedObjectContext]];
	[request setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO]]];
	
	if (_locationResultsController != nil) {
		return _locationResultsController;
	}
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"user.currentUser = %@", [NSNumber numberWithBool:NO]];
	[request setPredicate:predicate];
	
	_locationResultsController = [[NSFetchedResultsController alloc]
								  initWithFetchRequest:request
								  managedObjectContext:_managedObjectContext
								  sectionNameKeyPath:nil
								  cacheName:nil];
		
	[_locationResultsController setDelegate:self];
	
	return _locationResultsController;
}

- (NSMutableDictionary *) locationAnnotations {
	if (!_locationAnnotations) {
		_locationAnnotations = [[NSMutableDictionary alloc] init];
	}
	
	return _locationAnnotations;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

	[_mapView setDelegate:self];
	[_mapView setShowsUserLocation:YES];
	[_mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
	
    NSError *error;
    if (![[self locationResultsController] performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
	
	NSArray *locations = [self.locationResultsController fetchedObjects];
	for (Location *location in locations) {
		[self updateLocation:location];
	}
    
    if (![[self observationResultsController] performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail/Users/wnewman/Downloads/ios_development (1).cer
    }
	
	NSArray *observations = [self.observationResultsController fetchedObjects];
    NSLog(@"we initially found %lu observations", (unsigned long)observations.count);
	for (Observation *observation in observations) {
		[self updateObservation:observation];
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
			
			UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
			[rightButton addTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
			annotationView.rightCalloutAccessoryView = rightButton;
		} else {
            annotationView.annotation = annotation;
        }
		
        return annotationView;
    } else if ([annotation isKindOfClass:[ObservationAnnotation class]]) {
        ObservationAnnotation *observationAnnotation = annotation;
        UIImage *image = [ObservationImage imageForObservation:observationAnnotation.observation scaledToWidth:[NSNumber numberWithFloat:35]];
        MKAnnotationView *annotationView = (MKPinAnnotationView *) [_mapView dequeueReusableAnnotationViewWithIdentifier:[image accessibilityIdentifier]];
        
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:[image accessibilityIdentifier]];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
			
			UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
			[rightButton addTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
			annotationView.rightCalloutAccessoryView = rightButton;
			
            if (image == nil) {
                annotationView.image = [self imageWithImage:[UIImage imageNamed:@"defaultMarker"] scaledToWidth:35];
            } else {
                annotationView.image = image;
            }
		} else {
            annotationView.annotation = annotation;
        }
		
        return annotationView;
    }
	
    return nil;
}

- (void) mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
	if (view == [_mapView viewForAnnotation:_mapView.userLocation]) {
		UIButton *rightButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
		[rightButton addTarget:nil action:nil forControlEvents:UIControlEventTouchUpInside];
		view.rightCalloutAccessoryView = rightButton;
	}
}

-(UIImage*)imageWithImage: (UIImage*) sourceImage scaledToWidth: (float) i_width {
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

#pragma mark - NSFetchResultsController

- (void) controller:(NSFetchedResultsController *) controller
    didChangeObject:(id) object
	atIndexPath:(NSIndexPath *) indexPath
	forChangeType:(NSFetchedResultsChangeType) type
	newIndexPath:(NSIndexPath *)newIndexPath {
    
    if ([object isKindOfClass:[Observation class]]) {
        switch(type) {
                
            case NSFetchedResultsChangeInsert:
                [self updateObservation:object];
                break;
                
            case NSFetchedResultsChangeDelete:
                NSLog(@"Got delete for observation");
                break;
                
            case NSFetchedResultsChangeUpdate:
                [self updateObservation:object];
                break;
        }

    } else {
        switch(type) {
                
            case NSFetchedResultsChangeInsert:
                [self updateLocation:object];
                break;
                
            case NSFetchedResultsChangeDelete:
                NSLog(@"Got delete for location");
                break;
                
            case NSFetchedResultsChangeUpdate:
                [self updateLocation:object];
                break;
        }
    }
}

- (void) updateLocation:(Location *) location {
	User *user = location.user;
    
	LocationAnnotation *annotation = [self.locationAnnotations objectForKey:user.remoteId];
	if (annotation == nil) {
		annotation = [[LocationAnnotation alloc] initWithLocation:location];
		[_mapView addAnnotation:annotation];
		[self.locationAnnotations setObject:annotation forKey:user.remoteId];
	} else {
		[annotation setCoordinate:((GeoPoint *) location.geometry).location.coordinate];
	}
}

- (void) updateObservation: (Observation *) observation {
	ObservationAnnotation *annotation = [self.observationAnnotations objectForKey:observation.remoteId];
	if (annotation == nil) {
		annotation = [[ObservationAnnotation alloc] initWithObservation:observation];
		[self.observationAnnotations setObject:annotation forKey:observation.remoteId];
	}
	
	GeoPoint *point = observation.geometry;
    [annotation setCoordinate:point.location.coordinate];
    annotation.observation = observation;
	
	[_mapView addAnnotation:annotation];
}

- (void) mapView:(MKMapView *) mapView annotationView:(MKAnnotationView *) view calloutAccessoryControlTapped:(UIControl *) control {
	if ([view.annotation isKindOfClass:[LocationAnnotation class]] || view.annotation == _mapView.userLocation) {
		[self performSegueWithIdentifier:@"DisplayPersonSegue" sender:view];
	} else if ([view.annotation isKindOfClass:[ObservationAnnotation class]]) {
		[self performSegueWithIdentifier:@"DisplayObservationSegue" sender:view];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    if ([segue.identifier isEqualToString:@"DisplayPersonSegue"]) {
		User *user = nil;
		if ([sender annotation] == _mapView.userLocation) {
			user = [User fetchCurrentUserForManagedObjectContext:_managedObjectContext];
		} else {
			LocationAnnotation *annotation = [sender annotation];
			user = annotation.location.user;
		}
		
		PersonViewController *destinationViewController = segue.destinationViewController;
		[destinationViewController setUser:user];
		[destinationViewController setManagedObjectContext:_managedObjectContext];

    } else if ([segue.identifier isEqualToString:@"DisplayObservationSegue"]) {
		ObservationAnnotation *annotation = [sender annotation];
		
		ObservationViewController *destinationViewController = segue.destinationViewController;
		[destinationViewController setObservation:annotation.observation];
    }
}

@end

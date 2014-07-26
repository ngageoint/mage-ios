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

- (NSFetchedResultsController *) userResultsController {
	
	if (_userResultsController != nil) {
		return _userResultsController;
	}
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	[request setEntity:[NSEntityDescription entityForName:@"User" inManagedObjectContext:_managedObjectContext]];
	[request setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"location.timestamp" ascending:NO]]];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"remoteId != %@", [User currentUser].remoteId];
	[request setPredicate:predicate];
	
	_userResultsController = [[NSFetchedResultsController alloc]
								  initWithFetchRequest:request
								  managedObjectContext:_managedObjectContext
								  sectionNameKeyPath:nil
								  cacheName:nil];
		
	[_userResultsController setDelegate:self];
	
	return _userResultsController;
}

- (NSMutableDictionary *) locationAnnotations {
	if (!_locationAnnotations) {
		_locationAnnotations = [[NSMutableDictionary alloc] init];
	}
	
	return _locationAnnotations;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	[_mapView setDelegate:self];
	[_mapView setShowsUserLocation:YES];
	[_mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES];
	
	NSError *error;
    if (![[self userResultsController] performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
	
	NSArray *users = [_userResultsController fetchedObjects];
	for (User *user in users) {
		[self updateUser:user];
	}
    
    if (![[self observationResultsController] performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
	
	NSArray *observations = [_observationResultsController fetchedObjects];
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
    }
    else if ([annotation isKindOfClass:[ObservationAnnotation class]]) {
        ObservationAnnotation *observationAnnotation = annotation;
        UIImage *image = [ObservationImage imageForObservation:observationAnnotation.observation scaledToWidth:[NSNumber numberWithFloat:35]];
        MKPinAnnotationView *annotationView = (MKPinAnnotationView *) [_mapView dequeueReusableAnnotationViewWithIdentifier:[image accessibilityIdentifier]];
        
        if (annotationView == nil) {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:[image accessibilityIdentifier]];
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
                [self updateUser:object];
                break;
                
            case NSFetchedResultsChangeDelete:
                NSLog(@"Got delete for location");
                break;
                
            case NSFetchedResultsChangeUpdate:
                [self updateUser:object];
                break;
        }
    }
}

- (void) updateUser:(User *) user {
	LocationAnnotation *annotation = [_locationAnnotations objectForKey:user.remoteId];
	if (annotation == nil) {
		annotation = [[LocationAnnotation alloc] initWithLocation:user.location];
		[_mapView addAnnotation:annotation];
		[_locationAnnotations setObject:annotation forKey:user.remoteId];
	} else {
		[annotation setCoordinate:((GeoPoint *) user.location.geometry).location.coordinate];
	}
}

- (void) updateObservation: (Observation *) observation {
	ObservationAnnotation *annotation = [_observationAnnotations objectForKey:observation.remoteId];
	if (annotation == nil) {
		annotation = [[ObservationAnnotation alloc] init];
		[_observationAnnotations setObject:annotation forKey:observation.remoteId];
	}
	
	GeoPoint *point = observation.geometry;
    [annotation setCoordinate:point.location.coordinate];
    annotation.observation = observation;
	
	[_mapView addAnnotation:annotation];
}

- (void) mapView:(MKMapView *) mapView annotationView:(MKAnnotationView *) view calloutAccessoryControlTapped:(UIControl *) control {
	if ([view.annotation isKindOfClass:[LocationAnnotation class]]) {
		[self performSegueWithIdentifier:@"DisplayPersonSegue" sender:view];
	} else if ([view.annotation isKindOfClass:[ObservationAnnotation class]]) {
		[self performSegueWithIdentifier:@"DisplayObservationSegue" sender:view];
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    if ([segue.identifier isEqualToString:@"DisplayPersonSegue"]) {
		LocationAnnotation *annotation = [sender annotation];
		
		PersonViewController *destinationViewController = segue.destinationViewController;
		[destinationViewController setUser:annotation.location.user];
		[destinationViewController setManagedObjectContext:_managedObjectContext];
    } else if ([segue.identifier isEqualToString:@"DisplayObservationSegue"]) {
		ObservationAnnotation *annotation = [sender annotation];
		
		ObservationViewController *destinationViewController = segue.destinationViewController;
		[destinationViewController setObservation:annotation.observation];
    }
}

@end

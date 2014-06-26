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
#import "LocationAnnotation.h"

@interface MapViewController ()
	@property (nonatomic) NSMutableDictionary *locationAnnotations;
@end

@implementation MapViewController

- (NSManagedObjectContext *) managedObjectContext {
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
	
    return context;
}

- (NSFetchedResultsController *) locationResultsController {
	
	if (_locationResultsController != nil) {
		return _locationResultsController;
	}
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Location" inManagedObjectContext:self.managedObjectContext]];
	[fetchRequest setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO]]];
		
	_locationResultsController = [[NSFetchedResultsController alloc]
								  initWithFetchRequest:fetchRequest
								  managedObjectContext:self.managedObjectContext
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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	[_mapView setDelegate:self];
	
	NSError *error;
    if (![[self locationResultsController] performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
	
//	NSArray *locations = [_locationResultsController fetchedObjects];
//	for (Location *location in locations) {
//		[self updateLocation:location];
//	}
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (MKAnnotationView *)mapView:(MKMapView *) mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	
    static NSString *identifier = @"LocationAnnotation";
    if ([annotation isKindOfClass:[LocationAnnotation class]]) {
		LocationAnnotation *locationAnnotation = annotation;
		NSString *imageName = [self imageNameForTimestamp:locationAnnotation.timestamp];

        MKAnnotationView *annotationView = (MKAnnotationView *) [_mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:identifier];
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

- (NSString *) imageNameForTimestamp:(NSDate *) timestamp {
	if (!timestamp) return @"person";
	
	NSString *format = @"person_%@";
	NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:timestamp];
	if (interval <= 600) {
		return [NSString stringWithFormat:format, @"low"];
	} else if (interval <= 1200) {
		return [NSString stringWithFormat:format, @"medium"];
	} else {
		return [NSString stringWithFormat:format, @"high"];
	}
}

#pragma mark - NSFetchResultsController

- (void) controller:(NSFetchedResultsController *) controller
    didChangeObject:(id) object
	atIndexPath:(NSIndexPath *) indexPath
	forChangeType:(NSFetchedResultsChangeType) type
	newIndexPath:(NSIndexPath *)newIndexPath {
		
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

- (void) updateLocation:(Location *) location {
	NSLog(@"update location");
	LocationAnnotation *annotation = [_locationAnnotations objectForKey:location.userId];
	if (annotation == nil) {
		annotation = [[LocationAnnotation alloc] init];
		[_locationAnnotations setObject:annotation forKey:location.userId];
	}
	
	GeoPoint *point = location.geometry;
	[annotation setCoordinate:point.location.coordinate];
	[annotation setTimestamp:location.timestamp];
	
	[_mapView addAnnotation:annotation];
}

@end

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
#import "User+helper.h"
#import "Location+helper.h"
#import "LocationAnnotation.h"
#import "ObservationAnnotation.h"
#import "Observation.h"
#import <MapKit/MapKit.h>

@interface MapViewController ()
	@property (nonatomic) NSMutableDictionary *locationAnnotations;
    @property (nonatomic) NSMutableDictionary *observationAnnotations;
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

- (NSFetchedResultsController *) observationResultsController {
	
	if (_observationResultsController != nil) {
		return _observationResultsController;
	}
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Observation" inManagedObjectContext:self.managedObjectContext]];
    // TODO look at this, I think we changed Android to timestamp or something
	[fetchRequest setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"lastModified" ascending:NO]]];
    
	_observationResultsController = [[NSFetchedResultsController alloc]
								  initWithFetchRequest:fetchRequest
								  managedObjectContext:self.managedObjectContext
								  sectionNameKeyPath:nil
								  cacheName:nil];
    
	[_observationResultsController setDelegate:self];
	
	return _observationResultsController;
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
    
//    NSError *oerror;
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
	
    if ([annotation isKindOfClass:[LocationAnnotation class]]) {
		LocationAnnotation *locationAnnotation = annotation;
		NSString *imageName = [self imageNameForTimestamp:locationAnnotation.timestamp];
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
    else if ([annotation isKindOfClass:[ObservationAnnotation class]]) {
        ObservationAnnotation *observationAnnotation = annotation;
        NSString *imagePath = [self imagePathForObservation:observationAnnotation.observation];
        MKPinAnnotationView *annotationView = (MKPinAnnotationView *) [_mapView dequeueReusableAnnotationViewWithIdentifier:imagePath];
        
        if (annotationView == nil) {
            annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:imagePath];
            annotationView.enabled = YES;
            annotationView.canShowCallout = YES;
            if (imagePath == nil) {
                annotationView.image = [self imageWithImage:[UIImage imageNamed:@"defaultMarker"] scaledToWidth:35];
            } else {
                annotationView.image = [self imageWithImage:[UIImage imageWithContentsOfFile:imagePath] scaledToWidth:35];
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

- (NSString *) imagePathForObservation:(Observation *) observation {
	if (!observation) return nil;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *formId = [defaults objectForKey: @"formId"];
    NSString *rootIconFolder = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)objectAtIndex:0]stringByAppendingPathComponent:[NSString stringWithFormat: @"/form-%@/form/icons", formId]];
    
    NSString *type = [observation.properties objectForKey:@"type"];
    
    NSDictionary *form = [defaults objectForKey:@"form"];
    NSString *variantField = [form objectForKey:@"variantField"];
    NSMutableArray *iconProperties = [[NSMutableArray alloc] initWithArray: @[type]];
    if (variantField != nil) {
        [iconProperties addObject: [observation.properties objectForKey:variantField]];
    }

    BOOL foundIcon = NO;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    while(!foundIcon) {
        NSString *iconPath = [iconProperties componentsJoinedByString:@"/"];
        NSString *directoryToSearch = [rootIconFolder stringByAppendingPathComponent:iconPath];
        if ([fileManager fileExistsAtPath:directoryToSearch]) {
            NSArray *directoryContents = [fileManager contentsOfDirectoryAtPath:[rootIconFolder stringByAppendingPathComponent:iconPath] error:nil];
            if ([directoryContents count] != 0) {
                for (NSString *path in directoryContents) {
                    NSString *filename = [path lastPathComponent];
                    if ([filename hasPrefix:@"icon"]) {
                        return [[rootIconFolder stringByAppendingPathComponent:iconPath] stringByAppendingPathComponent:path];
                    }
                }
            }
        } else {
            if ([iconProperties count] == 0) {
                
                foundIcon = YES;
            }
            [iconProperties removeLastObject];
        }
    }
    return nil;
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
	LocationAnnotation *annotation = [_locationAnnotations objectForKey:location.userId];
	if (annotation == nil) {
		annotation = [[LocationAnnotation alloc] initWithLocation:location inManagedObjectContext:self.managedObjectContext];
		[_mapView addAnnotation:annotation];
		[_locationAnnotations setObject:annotation forKey:location.userId];
	} else {
		[annotation setCoordinate:((GeoPoint *) location.geometry).location.coordinate];
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

@end

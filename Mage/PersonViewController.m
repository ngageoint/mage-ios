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
#import "NSDate+DateTools.h"
#import "ObservationTableViewCell.h"
#import "ObservationViewController.h"

@interface PersonViewController()
	@property (nonatomic, strong) NSDateFormatter *dateFormatter;
	@property (nonatomic, strong) NSString *variantField;
@end

@implementation PersonViewController

- (NSDateFormatter *) dateFormatter {
	if (_dateFormatter == nil) {
		_dateFormatter = [[NSDateFormatter alloc] init];
		[_dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
		[_dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
	}
	
	return _dateFormatter;
}

- (NSFetchedResultsController *) observationResultsController {
	
	if (_observationResultsController != nil) {
		return _observationResultsController;
	}
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:[NSEntityDescription entityForName:@"Observation" inManagedObjectContext:_managedObjectContext]];
	[fetchRequest setSortDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO]]];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"userId == %@", _user.remoteId];
	[fetchRequest setPredicate:predicate];
	
	_observationResultsController = [[NSFetchedResultsController alloc]
									 initWithFetchRequest:fetchRequest
									 managedObjectContext:_managedObjectContext
									 sectionNameKeyPath:nil
									 cacheName:nil];
	
	[_observationResultsController setDelegate:self];
	
	return _observationResultsController;
}

- (void) viewDidLoad {
    [super viewDidLoad];
	
	GeoPoint *point = _user.location.geometry;
	CLLocationCoordinate2D coordinate = point.location.coordinate;
	
	_name.text = [NSString stringWithFormat:@"%@ (%@)", _user.name, _user.username];
	_timestamp.text = [self.dateFormatter stringFromDate:_user.location.timestamp];
	
	_latLng.text = [NSString stringWithFormat:@"%.6f, %.6f", coordinate.latitude, coordinate.longitude];
	
	if (_user.email.length != 0 && _user.phone.length != 0) {
		_contact1.text = _user.email;
		_contact2.text = _user.phone;
	} else if (_user.email.length != 0) {
		_contact1.text = _user.email;
	} else if (_user.phone.length != 0) {
		_contact1.text = _user.phone;
	}

	[_mapView setDelegate:self];
	CLLocationDistance latitudeMeters = 500;
	CLLocationDistance longitudeMeters = 500;
	NSDictionary *properties = _user.location.properties;
	id accuracyProperty = [properties valueForKeyPath:@"accuracy"];
	if (accuracyProperty != nil) {
		double accuracy = [accuracyProperty doubleValue];
		latitudeMeters = accuracy > latitudeMeters ? accuracy * 2.5 : latitudeMeters;
		longitudeMeters = accuracy > longitudeMeters ? accuracy * 2.5 : longitudeMeters;
		
		MKCircle *circle = [MKCircle circleWithCenterCoordinate:coordinate radius:accuracy];
		[_mapView addOverlay:circle];
	}
	
	MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, latitudeMeters, longitudeMeters);
	MKCoordinateRegion viewRegion = [self.mapView regionThatFits:region];
	[_mapView setRegion:viewRegion];
	
	LocationAnnotation *annotation = [[LocationAnnotation alloc] initWithLocation:_user.location];
	[_mapView addAnnotation:annotation];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *form = [defaults objectForKey:@"form"];
    _variantField = [form objectForKey:@"variantField"];
	
	_observationTableView.delegate = self;
	_observationTableView.dataSource = self;
	NSError *error;
    if (![[self observationResultsController] performFetch:&error]) {
        // Update to handle the error appropriately.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
	}
	
	NSArray *observations = [[self observationResultsController] fetchedObjects];
	NSLog(@"Got observations %lu", (unsigned long)[observations count]);

}

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillAppear:animated];
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	CAGradientLayer *maskLayer = [CAGradientLayer layer];
    
    //this is the anchor point for our gradient, in our case top left. setting it in the middle (.5, .5) will produce a radial gradient. our startPoint and endPoints are based off the anchorPoint
    maskLayer.anchorPoint = CGPointZero;
    
    // Setting our colors - since this is a mask the color itself is irrelevant - all that matters is the alpha.
	// A clear color will completely hide the layer we're masking, an alpha of 1.0 will completely show the masked view.
    UIColor *outerColor = [UIColor colorWithWhite:1.0 alpha:.25];
    UIColor *innerColor = [UIColor colorWithWhite:1.0 alpha:1.0];
    
    // An array of colors that dictatates the gradient(s)
    maskLayer.colors = @[(id)outerColor.CGColor, (id)outerColor.CGColor, (id)innerColor.CGColor, (id)innerColor.CGColor];
    
    // These are percentage points along the line defined by our startPoint and endPoint and correspond to our colors array.
	// The gradient will shift between the colors between these percentage points.
    maskLayer.locations = @[@0.0, @0.0, @0.35, @0.35f];
    maskLayer.bounds = _mapView.frame;
	UIView *view = [[UIView alloc] initWithFrame:_mapView.frame];
    
    view.backgroundColor = [UIColor blackColor];
    
    [self.view insertSubview:view belowSubview:self.mapView];
    self.mapView.layer.mask = maskLayer;
}

- (MKAnnotationView *)mapView:(MKMapView *) mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	
    if ([annotation isKindOfClass:[LocationAnnotation class]]) {
		LocationAnnotation *locationAnnotation = annotation;
        UIImage *image = [PersonImage imageForLocation:locationAnnotation.location];
        MKAnnotationView *annotationView = (MKAnnotationView *) [_mapView dequeueReusableAnnotationViewWithIdentifier:[image accessibilityIdentifier]];
        if (annotationView == nil) {
            annotationView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:[image accessibilityIdentifier]];
            annotationView.enabled = YES;
            annotationView.canShowCallout = NO;
            annotationView.image = image;

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
	
	NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:_user.location.timestamp];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    ObservationTableViewCell *cell = [self cellForObservationAtIndex:indexPath inTableView:tableView];
    
    return cell.bounds.size.height;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id  sectionInfo = [[_observationResultsController sections] objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	ObservationTableViewCell *observationCell = (ObservationTableViewCell *) cell;
	
	Observation *observation = [_observationResultsController objectAtIndexPath:indexPath];
	[observationCell populateCellWithObservation:observation];
}

- (ObservationTableViewCell *) cellForObservationAtIndex: (NSIndexPath *) indexPath inTableView: (UITableView *) tableView {
    Observation *observation = [_observationResultsController objectAtIndexPath:indexPath];
    NSString *CellIdentifier = @"observationCell";
    if (_variantField != nil && [[observation.properties objectForKey:_variantField] length] != 0) {
        CellIdentifier = @"observationVariantCell";
    }
	
    ObservationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ObservationTableViewCell *cell = [self cellForObservationAtIndex:indexPath inTableView:tableView];
	[self configureCell: cell atIndexPath:indexPath];
	
    return cell;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [_observationTableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id) anObject atIndexPath:(NSIndexPath *) indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *) newIndexPath {
		
    switch(type) {
			
        case NSFetchedResultsChangeInsert:
            [_observationTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeDelete:
            [_observationTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[_observationTableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
			
        case NSFetchedResultsChangeMove:
			[_observationTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
			[_observationTableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
			break;
    }
}

- (void) controller:(NSFetchedResultsController *)controller didChangeSection:(id) sectionInfo atIndex:(NSUInteger) sectionIndex forChangeType:(NSFetchedResultsChangeType) type {
	
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [_observationTableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
			
        case NSFetchedResultsChangeDelete:
            [_observationTableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void) controllerDidChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [_observationTableView endUpdates];
}

- (void) prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    if ([[segue identifier] isEqualToString:@"DisplayObservationSegue"]) {
        id destination = [segue destinationViewController];
        NSIndexPath *indexPath = [_observationTableView indexPathForCell:sender];
		Observation *observation = [_observationResultsController objectAtIndexPath:indexPath];
		[destination setObservation:observation];
    }
}

@end

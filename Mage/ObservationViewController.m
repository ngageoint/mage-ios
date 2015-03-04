//
//  ObservationViewerViewController.m
//  Mage
//
//  Created by Dan Barela on 4/29/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "ObservationViewController.h"
#import "GeoPoint.h"
#import <Observation+helper.h>
#import "ObservationAnnotation.h"
#import "ObservationImage.h"
#import "ObservationPropertyTableViewCell.h"
#import <User.h>
#import "AttachmentCell.h"
#import "ImageViewerViewController.h"
#import "ObservationEditViewController.h"
#import <Server+helper.h>
#import "MapDelegate.h"
#import "ObservationDataStore.h"
#import <Event+helper.h>

@interface ObservationViewController ()

@property (weak, nonatomic) IBOutlet MKMapView *map;
@property (strong, nonatomic) IBOutlet MapDelegate *mapDelegate;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;

@property (nonatomic, strong) IBOutlet ObservationDataStore *observationDataStore;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation ObservationViewController

- (NSDateFormatter *) dateFormatter {
	if (_dateFormatter == nil) {
		_dateFormatter = [[NSDateFormatter alloc] init];
		[_dateFormatter setTimeZone:[NSTimeZone systemTimeZone]];
		[_dateFormatter setDateFormat:@"yyyy-MM-dd hh:mm:ss"];
	}
	
	return _dateFormatter;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
	NSString *name = [_observation.properties valueForKey:@"type"];
	self.navigationItem.title = name;
//    self.observation = [self.observation MR_inContext:[NSManagedObjectContext MR_defaultContext]];
//    [[self.observation managedObjectContext] refreshObject:self.observation mergeChanges:YES];
    Observations *observations = [Observations observationsForObservation:self.observation];
    [self.observationDataStore startFetchControllerWithObservations:observations];
    if (self.mapDelegate != nil) {
        [self.mapDelegate setObservations:observations];
        self.observationDataStore.observationSelectionDelegate = self.mapDelegate;
        [self.mapDelegate selectedObservation:_observation];
    }
    [self.mapDelegate setObservations:observations];
    
    self.userLabel.text = _observation.user.name;
    
    self.userLabel.text = [NSString stringWithFormat:@"%@ (%@)", _observation.user.name, _observation.user.username];
	self.timestampLabel.text = [self.dateFormatter stringFromDate:_observation.timestamp];
	
	self.locationLabel.text = [NSString stringWithFormat:@"%.6f, %.6f", _observation.location.coordinate.latitude, _observation.location.coordinate.longitude];
    
    CLLocationDistance latitudeMeters = 500;
    CLLocationDistance longitudeMeters = 500;
    NSDictionary *properties = self.observation.properties;
    id accuracyProperty = [properties valueForKeyPath:@"accuracy"];
    if (accuracyProperty != nil) {
        double accuracy = [accuracyProperty doubleValue];
        latitudeMeters = accuracy > latitudeMeters ? accuracy * 2.5 : latitudeMeters;
        longitudeMeters = accuracy > longitudeMeters ? accuracy * 2.5 : longitudeMeters;
    }
    
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(self.observation.location.coordinate, latitudeMeters, longitudeMeters);
    MKCoordinateRegion viewRegion = [self.mapView regionThatFits:region];
    
    [self.mapDelegate selectedObservation:self.observation region:viewRegion];
    
    self.attachmentCollectionDataStore.attachmentSelectionDelegate = self;
    if (self.attachmentCollectionDataStore.observation == nil) {
        self.attachmentCollectionDataStore.observation = _observation;
        [self.attachmentCollection reloadData];
    } else {
        [self.attachmentCollection reloadData];
    }
    
    [self.propertyTable reloadData];
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

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_observation.properties count];
}

- (void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	ObservationPropertyTableViewCell *observationCell = (ObservationPropertyTableViewCell *) cell;
    id value = [[_observation.properties allObjects] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]];
    id title = [observationCell.fieldDefinition objectForKey:@"title"];
    if (title == nil) {
        title = [[_observation.properties allKeys] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]];
    }
    [observationCell populateCellWithKey:title andValue:value];
}

- (ObservationPropertyTableViewCell *) cellForObservationAtIndex: (NSIndexPath *) indexPath inTableView: (UITableView *) tableView {
    id key = [[_observation.properties allKeys] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]];
    Event *event = [Event MR_findFirstByAttribute:@"remoteId" withValue:[Server currentEventId]];
    NSDictionary *form = event.form;
    
    for (id field in [form objectForKey:@"fields"]) {
        NSString *fieldName = [field objectForKey:@"name"];
        if ([key isEqualToString: fieldName]) {
            NSString *type = [field objectForKey:@"type"];
            NSString *CellIdentifier = [NSString stringWithFormat:@"observationCell-%@", type];
            ObservationPropertyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            if (cell == nil) {
                CellIdentifier = @"observationCell-generic";
                cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
            }
            cell.fieldDefinition = field;
            return cell;
        }
    }
    
    NSString *CellIdentifier = @"observationCell-generic";
    ObservationPropertyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ObservationPropertyTableViewCell *cell = [self cellForObservationAtIndex:indexPath inTableView:tableView];
	[self configureCell: cell atIndexPath:indexPath];
	
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    ObservationPropertyTableViewCell *cell = [self cellForObservationAtIndex:indexPath inTableView:tableView];
    if ([[cell.fieldDefinition objectForKey:@"archived"] intValue] == 1) {
        return 0.0;
    }
    return [cell getCellHeightForValue:[[_observation.properties allObjects] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]]];
}

- (void) selectedAttachment:(Attachment *)attachment {
    NSLog(@"clicked attachment %@", attachment.url);
    [self performSegueWithIdentifier:@"viewImageSegue" sender:attachment];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[_observation.properties valueForKey:@"type"] style: UIBarButtonItemStyleBordered target:nil action:nil];
    
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"viewImageSegue"])
    {
        // Get reference to the destination view controller
        ImageViewerViewController *vc = [segue destinationViewController];
        
        // Pass any objects to the view controller here, like...
        [vc setAttachment:sender];
    } else if ([[segue identifier] isEqualToString:@"observationEditSegue"]) {
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style: UIBarButtonItemStyleBordered target:nil action:nil];
        ObservationEditViewController *oevc = [segue destinationViewController];
        [oevc setObservation:_observation];
    }
}

@end

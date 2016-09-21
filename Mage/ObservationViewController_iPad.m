//
//  ObservationViewerViewController.m
//  Mage
//
//

#import "ObservationViewController_iPad.h"
#import "GeoPoint.h"
#import "Observation.h"
#import "ObservationAnnotation.h"
#import "ObservationImage.h"
#import "ObservationPropertyTableViewCell.h"
#import "User.h"
#import "Role.h"
#import "AttachmentCell.h"
#import "AttachmentViewController.h"
#import "ObservationEditViewController.h"
#import "Server.h"
#import "MapDelegate.h"
#import "ObservationDataStore.h"
#import "Event.h"
#import "NSDate+display.h"
#import "Attachment+Thumbnail.h"
#import "ObservationFields.h"

@interface ObservationViewController_iPad ()

@property (weak, nonatomic) IBOutlet MKMapView *map;
@property (strong, nonatomic) IBOutlet MapDelegate *mapDelegate;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (weak, nonatomic) IBOutlet UILabel *primaryFieldLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondaryFieldLabel;
@property (nonatomic, strong) IBOutlet ObservationDataStore *observationDataStore;
@property (strong, nonatomic) NSArray *fields;
@property (strong, nonatomic) NSString *variantField;
@end

@implementation ObservationViewController_iPad

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController setNavigationBarHidden:NO];
    
    [self.propertyTable setEstimatedRowHeight:44.0f];
    [self.propertyTable setRowHeight:UITableViewAutomaticDimension];
    
    self.attachmentCollectionDataStore.attachmentFormatName = AttachmentMediumSquare;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    User *user = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
    if ([self userHasEditPermissions:user]) {
        self.editButton.style = UIBarButtonItemStylePlain;
        self.editButton.enabled = YES;
        self.editButton.title = @"Edit";
    } else {
        self.editButton.style = UIBarButtonItemStylePlain;
        self.editButton.enabled = NO;
        self.editButton.title = nil;
    }
    
    NSString *name = [self.observation.properties valueForKey:@"type"];
    if (name != nil) {
        self.primaryFieldLabel.text = name;
    } else {
        self.primaryFieldLabel.text = @"Observation";
    }
    
    Event *event = [Event MR_findFirstByAttribute:@"remoteId" withValue:[Server currentEventId]];
    NSDictionary *form = event.form;
    NSString *variantField = [form objectForKey:@"variantField"];
    NSString *variantText = [self.observation.properties objectForKey:variantField];
    if (variantField != nil && variantText != nil && [variantText isKindOfClass:[NSString class]] && variantText.length > 0) {
        self.secondaryFieldLabel.text = [self.observation.properties objectForKey:variantField];
    } else {
        [self.secondaryFieldLabel removeFromSuperview];
    }
    
    NSMutableArray *generalProperties = [NSMutableArray arrayWithObjects:@"timestamp", @"type", @"geometry", nil];
    self.variantField = [event.form objectForKey:@"variantField"];
    if (self.variantField) {
        [generalProperties addObject:self.variantField];
    }
    
    NSMutableDictionary *propertiesWithValue = [self.observation.properties mutableCopy];
    NSMutableArray *keyWithNoValue = [[propertiesWithValue allKeysForObject:@""] mutableCopy];
    [keyWithNoValue addObjectsFromArray:[propertiesWithValue allKeysForObject:@[]]];
    [propertiesWithValue removeObjectsForKeys:keyWithNoValue];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"archived = %@ AND (NOT (SELF.name IN %@)) AND (SELF.name IN %@) AND type IN %@", nil, generalProperties, [propertiesWithValue allKeys], [ObservationFields fields]];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES];
    self.fields = [[[event.form objectForKey:@"fields"] filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:@[sortDescriptor]];
    
	self.navigationItem.title = name;
    Observations *observations = [Observations observationsForObservation:self.observation];
    [self.observationDataStore startFetchControllerWithObservations:observations];
    if (self.mapDelegate != nil) {
        [self.mapDelegate setObservations:observations];
        self.observationDataStore.observationSelectionDelegate = self.mapDelegate;
        [self.mapDelegate selectedObservation:_observation];
    }
    [self.mapDelegate setObservations:observations];
    
    self.userLabel.text = _observation.user.name;
    
    self.userLabel.text = self.observation.user.name;
    self.timestampLabel.text = [self.observation.timestamp formattedDisplayDate];
	
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

-(UIImage*) imageWithImage: (UIImage*) sourceImage scaledToWidth: (float) i_width {
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
    return [self.fields count];
}

- (void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	ObservationPropertyTableViewCell *observationCell = (ObservationPropertyTableViewCell *) cell;
    
    NSDictionary *field = [self.fields objectAtIndex:[indexPath row]];
    id title = [field objectForKey:@"title"];
    id value = [self.observation.properties objectForKey:[field objectForKey:@"name"]];
    
    [observationCell populateCellWithKey:title andValue:value];
}

- (ObservationPropertyTableViewCell *) cellForObservationAtIndex: (NSIndexPath *) indexPath inTableView: (UITableView *) tableView {
    NSDictionary *field = [self.fields objectAtIndex:[indexPath row]];
    ObservationPropertyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[field valueForKey:@"type"]];
    cell.fieldDefinition = field;
    
    return cell;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ObservationPropertyTableViewCell *cell = [self cellForObservationAtIndex:indexPath inTableView:tableView];
	[self configureCell: cell atIndexPath:indexPath];
    [cell.valueTextView.textContainer setLineBreakMode:NSLineBreakByWordWrapping];

    return cell;
}

- (void) selectedAttachment:(Attachment *)attachment {
    NSLog(@"clicked attachment %@", attachment.url);
    [self performSegueWithIdentifier:@"viewImageSegue" sender:attachment];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[_observation.properties valueForKey:@"type"] style: UIBarButtonItemStylePlain target:nil action:nil];
    
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"viewImageSegue"]) {
        AttachmentViewController *vc = [segue destinationViewController];
        [vc setAttachment:sender];
        [vc setTitle:@"Attachment"];
    } else if ([[segue identifier] isEqualToString:@"observationEditSegue"]) {
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style: UIBarButtonItemStylePlain target:nil action:nil];
        ObservationEditViewController *oevc = [segue destinationViewController];
        [oevc setObservation:_observation];
    }
}

- (IBAction) getDirections:(id)sender {
    CLLocationCoordinate2D coordinate = ((GeoPoint *) self.observation.geometry).location.coordinate;
    NSURL *testURL = [NSURL URLWithString:@"comgooglemaps-x-callback://"];
    if ([[UIApplication sharedApplication] canOpenURL:testURL]) {
        NSString *directionsRequest = [NSString stringWithFormat:@"%@://?daddr=%f,%f&x-success=%@&x-source=%s",
                                       @"comgooglemaps-x-callback",
                                       coordinate.latitude,
                                       coordinate.longitude,
                                       @"mage://?resume=true",
                                       "MAGE"];
        NSURL *directionsURL = [NSURL URLWithString:directionsRequest];
        [[UIApplication sharedApplication] openURL:directionsURL];
    } else {
        NSLog(@"Can't use comgooglemaps-x-callback:// on this device.");
        MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:coordinate addressDictionary:nil];
        MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
        [mapItem setName:[self.observation.properties valueForKey:@"type"]];
        NSDictionary *options = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
        [mapItem openInMapsWithLaunchOptions:options];
    }
}

- (BOOL) userHasEditPermissions:(User *) user {
    return [user.role.permissions containsObject:@"UPDATE_OBSERVATION_ALL"] || [user.role.permissions containsObject:@"UPDATE_OBSERVATION_EVENT"];
}


@end

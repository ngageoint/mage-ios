//
//  ObservationViewController.m
//  MAGE
//
//  Created by William Newman on 11/2/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationViewController.h"
#import "Server.h"
#import "Event.h"
#import "User.h"
#import "Role.h"
#import "ObservationDataStore.h"
#import "ObservationFields.h"
#import "ObservationFavorite.h"
#import "ObservationImportant.h"
#import "ObservationPropertyTableViewCell.h"
#import "ObservationEditViewController.h"
#import "UserTableViewController.h"
#import "MapDelegate.h"
#import "AttachmentViewController.h"

@interface ObservationViewController ()<NSFetchedResultsControllerDelegate>
@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;
@property (weak, nonatomic) IBOutlet UILabel *primaryFieldLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondaryFieldLabel;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) IBOutlet MapDelegate *mapDelegate;
@property (weak, nonatomic) IBOutlet ObservationDataStore *observationDataStore;

@property (strong, nonatomic) User *currentUser;
@property (strong, nonatomic) NSArray *fields;
@property (strong, nonatomic) NSString *variantField;
@property (nonatomic, strong) NSFetchedResultsController *favoritesFetchedResultsController;
@property (nonatomic, strong) NSFetchedResultsController *importantFetchedResultsController;
@end

@implementation ObservationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.currentUser = [User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]];
    
    [self.propertyTable setEstimatedRowHeight:44.0f];
    [self.propertyTable setRowHeight:UITableViewAutomaticDimension];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.tableLayout = [[NSMutableArray alloc] init];
    
    self.favoritesFetchedResultsController = [ObservationFavorite MR_fetchAllSortedBy:@"observation.timestamp"
                                                                            ascending:NO
                                                                        withPredicate:[NSPredicate predicateWithFormat:@"observation == %@", self.observation]
                                                                              groupBy:nil
                                                                             delegate:self
                                                                            inContext:[NSManagedObjectContext MR_defaultContext]];
    
    self.importantFetchedResultsController = [ObservationImportant MR_fetchAllSortedBy:@"observation.timestamp"
                                                                             ascending:NO
                                                                         withPredicate:[NSPredicate predicateWithFormat:@"observation == %@", self.observation]
                                                                               groupBy:nil
                                                                              delegate:self
                                                                             inContext:[NSManagedObjectContext MR_defaultContext]];
    
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
    self.navigationItem.title = self.navigationItem.title = name;

    Observations *observations = [Observations observationsForObservation:self.observation];
    [self.observationDataStore startFetchControllerWithObservations:observations];
    if (self.mapDelegate != nil) {
        [self.mapDelegate setObservations:observations];
        self.observationDataStore.observationSelectionDelegate = self.mapDelegate;
        [self.mapDelegate selectedObservation:self.observation];
    }
    [self.mapDelegate setObservations:observations];
    
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
    
    [self.tableLayout addObject:[self getHeaderSection]];
    [self.tableLayout addObject:[self getAttachmentsSection]];

    NSMutableArray *importantSection = [[NSMutableArray alloc] init];
    if ([self canEditObservationImportant] && !self.observation.isImportant) {
        [importantSection addObject:@"addImportant"];
    } else if (self.observation.isImportant) {
        [importantSection addObject:@"updateImportant"];
    }
    [self.tableLayout addObject:importantSection];
    
    Event *event = [Event MR_findFirstByAttribute:@"remoteId" withValue:[Server currentEventId]];
    NSDictionary *form = event.form;
    NSString *variantField = [form objectForKey:@"variantField"];
    NSString *variantText = [self.observation.properties objectForKey:variantField];
    if (variantField != nil && variantText != nil && [variantText isKindOfClass:[NSString class]] && variantText.length > 0) {
        self.secondaryFieldLabel.text = [self.observation.properties objectForKey:variantField];
    } else {
        [self.secondaryFieldLabel removeFromSuperview];
    }
    
    NSMutableDictionary *propertiesWithValue = [self.observation.properties mutableCopy];
    NSMutableArray *keyWithNoValue = [[propertiesWithValue allKeysForObject:@""] mutableCopy];
    [keyWithNoValue addObjectsFromArray:[propertiesWithValue allKeysForObject:@[]]];
    [propertiesWithValue removeObjectsForKeys:keyWithNoValue];
    
    NSMutableArray *generalProperties = [NSMutableArray arrayWithObjects:@"timestamp", @"type", @"geometry", nil];
    self.variantField = [event.form objectForKey:@"variantField"];
    if (self.variantField) {
        [generalProperties addObject:self.variantField];
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"archived = %@ AND (NOT (SELF.name IN %@)) AND (SELF.name IN %@) AND type IN %@", nil, generalProperties, [propertiesWithValue allKeys], [ObservationFields fields]];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES];
    self.fields = [[[event.form objectForKey:@"fields"] filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:@[sortDescriptor]];
    
    [self.propertyTable reloadData];
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    self.favoritesFetchedResultsController.delegate = nil;
    self.favoritesFetchedResultsController = nil;
    
    self.importantFetchedResultsController.delegate = nil;
    self.importantFetchedResultsController = nil;
}

- (NSMutableArray *) getHeaderSection {
    return [[NSMutableArray alloc] init];
}

- (NSMutableArray *) getAttachmentsSection {
    return [[NSMutableArray alloc] init];
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
    return self.tableLayout.count + 1;
}

- (NSInteger) tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
    if (section < self.tableLayout.count) {
        NSLog(@"header section count %lu", (unsigned long)[self.tableLayout[section] count]);
        return [self.tableLayout[section] count];
    } else {
        NSLog(@"fields count %lu", (unsigned long)[self.fields count]);
        return [self.fields count];
    }
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section < self.tableLayout.count) {
        id cell = [tableView dequeueReusableCellWithIdentifier:self.tableLayout[indexPath.section][indexPath.row]];
        [cell configureCellForObservation:self.observation];
        
        if ([cell respondsToSelector:@selector(setAttachmentSelectionDelegate:)]) {
            [cell setAttachmentSelectionDelegate:self];
        }
        
        if ([cell respondsToSelector:@selector(setObservationImportantDelegate:)]) {
            [cell setObservationImportantDelegate:self];
        }
        
        return cell;
    } else {
        ObservationPropertyTableViewCell *cell = [self cellForObservationAtIndex:indexPath inTableView:tableView];
        [self configureCell:cell atIndexPath:indexPath];
        [cell.valueTextView.textContainer setLineBreakMode:NSLineBreakByWordWrapping];
        
        cell.separatorInset = UIEdgeInsetsMake(0.f, cell.bounds.size.width, 0.f, 0.f);
        
        return cell;
    }
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section < self.tableLayout.count && [self.tableLayout[section] count] == 0) {
        return 0.01;
    }
    
    return UITableViewAutomaticDimension;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}

- (void) selectedAttachment:(Attachment *)attachment {
    NSLog(@"clicked attachment %@", attachment.url);
    [self performSegueWithIdentifier:@"viewImageSegue" sender:attachment];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[self.observation.properties valueForKey:@"type"] style: UIBarButtonItemStylePlain target:nil action:nil];
    
    // Make sure your segue name in storyboard is the same as this line
    if ([segue.identifier isEqualToString:@"viewImageSegue"]) {
        // Get reference to the destination view controller
        AttachmentViewController *vc = [segue destinationViewController];
        [vc setAttachment:sender];
        [vc setTitle:@"Attachment"];
    } else if ([segue.identifier isEqualToString:@"observationEditSegue"]) {
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style: UIBarButtonItemStylePlain target:nil action:nil];
        ObservationEditViewController *vc = [segue destinationViewController];
        [vc setObservation:self.observation];
    } else if ([segue.identifier isEqualToString:@"FavoriteUsersSegue"]) {
        NSMutableArray *userIds = [[NSMutableArray alloc] init];
        [self.observation.favorites enumerateObjectsUsingBlock:^(ObservationFavorite * _Nonnull favorite, BOOL * _Nonnull stop) {
            [userIds addObject:favorite.userId];
        }];
        
        UserTableViewController *vc = [segue destinationViewController];
        vc.userIds = userIds;
    }
}

- (BOOL) userHasEditPermissions:(User *) user {
    return [user.role.permissions containsObject:@"UPDATE_OBSERVATION_ALL"] || [user.role.permissions containsObject:@"UPDATE_OBSERVATION_EVENT"];
}

- (BOOL) canEditObservationImportant {
    return self.currentUser && [self.currentUser.role.permissions containsObject:@"UPDATE_EVENT"];
}

- (IBAction) observationFavoriteTapped:(id)sender {
    __weak typeof(self) weakSelf = self;
    [self.observation toggleFavoriteWithCompletion:^(BOOL contextDidSave, NSError * _Nullable error) {
        // No-op favorites FRC will catch update and handle
    }];
}

- (void) updateFavorites {
    
}

-(IBAction) observationShareTapped:(id)sender {
    [self.observation shareObservationForViewController:self];
}

- (IBAction) observationDirectionsTapped:(id)sender {
    CLLocationCoordinate2D coordinate = ((GeoPoint *) self.observation.geometry).location.coordinate;
    
    NSURL *mapsUrl = [NSURL URLWithString:@"comgooglemaps-x-callback://"];
    if ([[UIApplication sharedApplication] canOpenURL:mapsUrl]) {
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

- (void) removeObservationImportant {
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"Remove Important Flag"
                                                                              message:@"Are you sure you want to remove this observations important flag?"
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Remove Flag" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        __weak typeof(self) weakSelf = self;
        [self.observation removeImportantWithCompletion:^(BOOL contextDidSave, NSError * _Nullable error) {
            [weakSelf updateImportant];
        }];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (void) flagObservationImportant {
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle:nil
                                                                              message:@"Description (optional)"
                                                                       preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
        textField.placeholder = @"description";
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.borderStyle = UITextBorderStyleNone;
        textField.backgroundColor = [UIColor clearColor];
        
        ObservationImportant *important = self.observation.observationImportant;
        if (important && [important.important isEqualToNumber:[NSNumber numberWithBool:YES]]) {
            textField.text = important.reason;
        }
    }];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        NSArray * textfields = alertController.textFields;
        UITextField *textField = textfields[0];
        
        __weak typeof(self) weakSelf = self;
        [self.observation flagImportantWithDescription:textField.text completion:^(BOOL contextDidSave, NSError * _Nullable error) {
            [weakSelf updateImportant];
        }];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void) updateImportant {
    BOOL isImportant = self.observation.isImportant;
    if (!isImportant && [self canEditObservationImportant]) {
        [self.tableLayout replaceObjectAtIndex:2 withObject:@[@"addImportant"]];
        [self.propertyTable reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationFade];
    } else if (isImportant) {
        [self.tableLayout replaceObjectAtIndex:2 withObject:@[@"updateImportant"]];
        [self.propertyTable reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationFade];
    } else if (!isImportant) {
        [self.tableLayout replaceObjectAtIndex:2 withObject:@[]];
        [self.propertyTable reloadSections:[NSIndexSet indexSetWithIndex:2] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id) anObject atIndexPath:(NSIndexPath *) indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *) newIndexPath {
    [[NSManagedObjectContext MR_defaultContext] refreshObject:self.observation mergeChanges:NO];

    if ([anObject isKindOfClass:[ObservationFavorite class]]) {
        [self updateFavorites];
    } else if ([anObject isKindOfClass:[ObservationImportant class]]) {
        [self updateImportant];
    }
}

@end

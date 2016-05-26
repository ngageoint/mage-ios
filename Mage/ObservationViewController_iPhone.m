//
//  ObservationViewController_iPhone.m
//  MAGE
//
//

#import "ObservationViewController_iPhone.h"
#import "Observations.h"
#import "ObservationPropertyTableViewCell.h"
#import "Server.h"
#import "ObservationHeaderTableViewCell.h"
#import "AttachmentViewController.h"
#import "ObservationEditViewController.h"
#import "ObservationHeaderAttachmentTableViewCell.h"
#import "Event.h"
#import "Role.h"
#import "ObservationFields.h"

@interface ObservationViewController_iPhone()
@property (strong, nonatomic) NSMutableArray *tableLayout;
@property (strong, nonatomic) NSString *variantField;
@property (strong, nonatomic) NSArray *fields;
@end

@implementation ObservationViewController_iPhone

-(void) viewDidLoad {
    [super viewDidLoad];
    
    [self.propertyTable setEstimatedRowHeight:44.0f];
    [self.propertyTable setRowHeight:UITableViewAutomaticDimension];
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
    self.navigationItem.title = name;
    
    self.tableLayout = [[NSMutableArray alloc] init];
    NSArray *headerSection = [[NSArray alloc] initWithObjects:@"header", @"map", @"directions", nil];
    NSArray *attachmentSection = [[NSArray alloc] initWithObjects:@"attachments", nil];
    [self.tableLayout addObject:headerSection];
    if (self.observation.attachments.count != 0) {
        [self.tableLayout addObject:attachmentSection];
    }
    
    self.propertyTable.delegate = self;
    self.propertyTable.dataSource = self;
    
    Event *event = [Event MR_findFirstByAttribute:@"remoteId" withValue:[Server currentEventId]];
    NSMutableArray *generalProperties = [NSMutableArray arrayWithObjects:@"timestamp", @"type", @"geometry", nil];
    self.variantField = [event.form objectForKey:@"variantField"];;
    if (self.variantField) {
        [generalProperties addObject:self.variantField];
    }
    
    NSMutableDictionary *propertiesWithValue = [self.observation.properties mutableCopy];
    NSArray *keysWithEmptyString = [propertiesWithValue allKeysForObject:@""];
    [propertiesWithValue removeObjectsForKeys:keysWithEmptyString];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"archived = %@ AND (NOT (SELF.name IN %@)) AND (SELF.name IN %@) AND type IN %@", nil, generalProperties, [propertiesWithValue allKeys], [ObservationFields fields]];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES];
    self.fields = [[[event.form objectForKey:@"fields"] filteredArrayUsingPredicate:predicate] sortedArrayUsingDescriptors:@[sortDescriptor]];
    
    [self.propertyTable reloadData];
}

- (UIImage*) imageWithImage: (UIImage*) sourceImage scaledToWidth: (float) i_width {
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

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return self.tableLayout.count + 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < self.tableLayout.count) {
        return [(NSArray *) self.tableLayout[section] count];
    } else {
        return [self.fields count];
    }
}

- (void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == self.tableLayout.count) {
        ObservationPropertyTableViewCell *observationCell = (ObservationPropertyTableViewCell *) cell;
        NSDictionary *field = [self.fields objectAtIndex:[indexPath row]];
        id title = [field objectForKey:@"title"];
        id value = [self.observation.properties objectForKey:[field objectForKey:@"name"]];
        
        [observationCell populateCellWithKey:title andValue:value];
    }
}

- (ObservationPropertyTableViewCell *) cellForObservationAtIndex: (NSIndexPath *) indexPath inTableView: (UITableView *) tableView {
    NSDictionary *field = [self.fields objectAtIndex:[indexPath row]];
    ObservationPropertyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:[field objectForKey:@"type"]];
    cell.fieldDefinition = field;
    
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section < self.tableLayout.count) {
        ObservationHeaderTableViewCell *cell = (ObservationHeaderTableViewCell *)[tableView dequeueReusableCellWithIdentifier:self.tableLayout[indexPath.section][indexPath.row]];
        [cell configureCellForObservation:self.observation];
        if ([cell isKindOfClass:[ObservationHeaderAttachmentTableViewCell class]]) {
            ObservationHeaderAttachmentTableViewCell *attachmentCell = (ObservationHeaderAttachmentTableViewCell *)cell;
            [attachmentCell setAttachmentSelectionDelegate: self];
        }
        return cell;
    } else {
        ObservationPropertyTableViewCell *cell = [self cellForObservationAtIndex:indexPath inTableView:tableView];
        [self configureCell: cell atIndexPath:indexPath];
        
        return cell;
    }
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return CGFLOAT_MIN;
    }
    
    return UITableViewAutomaticDimension;
}

- (void) selectedAttachment:(Attachment *)attachment {
    NSLog(@"clicked attachment %@", attachment.url);
    [self performSegueWithIdentifier:@"viewImageSegue" sender:attachment];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:[_observation.properties valueForKey:@"type"] style: UIBarButtonItemStylePlain target:nil action:nil];
    
    // Make sure your segue name in storyboard is the same as this line
    if ([[segue identifier] isEqualToString:@"viewImageSegue"]) {
        // Get reference to the destination view controller
        AttachmentViewController *vc = [segue destinationViewController];
        [vc setAttachment:sender];
        [vc setTitle:@"Attachment"];
    } else if ([[segue identifier] isEqualToString:@"observationEditSegue"]) {
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style: UIBarButtonItemStylePlain target:nil action:nil];
        ObservationEditViewController *vc = [segue destinationViewController];
        [vc setObservation:_observation];
    }
}

- (BOOL) userHasEditPermissions:(User *) user {
    return [user.role.permissions containsObject:@"UPDATE_OBSERVATION_ALL"] || [user.role.permissions containsObject:@"UPDATE_OBSERVATION_EVENT"];
}


@end

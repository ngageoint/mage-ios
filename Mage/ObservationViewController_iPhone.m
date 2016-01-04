//
//  ObservationViewController_iPhone.m
//  MAGE
//
//

#import "ObservationViewController_iPhone.h"
#import "Observations.h"
#import "ObservationPropertyTableViewCell.h"
#import <Server+helper.h>
#import "ObservationHeaderTableViewCell.h"
#import "ImageViewerViewController.h"
#import "ObservationEditViewController.h"
#import "ObservationHeaderAttachmentTableViewCell.h"
#import <Event+helper.h>

@interface ObservationViewController_iPhone()

@property (strong, nonatomic) NSMutableArray *tableLayout;
@property (strong, nonatomic) NSArray *fields;
@property (strong, nonatomic) NSString *variantField;

@end

@implementation ObservationViewController_iPhone

-(void) viewDidLoad {
    [super viewDidLoad];
    
    [self.propertyTable setEstimatedRowHeight:44.0f];
    [self.propertyTable setRowHeight:UITableViewAutomaticDimension];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    NSString *name = [self.observation.properties valueForKey:@"type"];
    self.navigationItem.title = name;
    
    self.tableLayout = [[NSMutableArray alloc] init];
    NSArray *headerSection = [[NSArray alloc] initWithObjects:@"observation-header", @"observation-map", @"observation-map-directions", nil];
    NSArray *attachmentSection = [[NSArray alloc] initWithObjects:@"observation-attachments", nil];
    [self.tableLayout addObject:headerSection];
    if (self.observation.attachments.count != 0) {
        [self.tableLayout addObject:attachmentSection];
    }
    
    self.propertyTable.delegate = self;
    self.propertyTable.dataSource = self;
    
    Event *event = [Event MR_findFirstByAttribute:@"remoteId" withValue:[Server currentEventId]];
    self.variantField = [event.form objectForKey:@"variantField"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"archived = %@ AND (NOT (SELF.name IN %@))", nil, @[@"timestamp", @"type", @"geometry", self.variantField]];
    self.fields = [[event.form objectForKey:@"fields"] filteredArrayUsingPredicate:predicate];
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

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return self.tableLayout.count + 1;
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < self.tableLayout.count) {
        return [(NSArray *)self.tableLayout[section] count];
    } else {
        NSArray *fieldNames = [self.fields valueForKey:@"name"];
        NSDictionary *filtered = [self.observation.properties dictionaryWithValuesForKeys:fieldNames];
        return [filtered count];
    }
}

- (void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == self.tableLayout.count) {
        ObservationPropertyTableViewCell *observationCell = (ObservationPropertyTableViewCell *) cell;
        id value = [[self.observation.properties allObjects] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]];
        id title = [observationCell.fieldDefinition objectForKey:@"title"];
        if (title == nil) {
            title = [[self.observation.properties allKeys] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]];
        }
        [observationCell populateCellWithKey:title andValue:value];
    }
}

- (ObservationPropertyTableViewCell *) cellForObservationAtIndex: (NSIndexPath *) indexPath inTableView: (UITableView *) tableView {
    id key = [[self.observation.properties allKeys] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]];
    
    for (id field in self.fields) {
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
        ImageViewerViewController *vc = [segue destinationViewController];
        [vc setAttachment:sender];
        [vc setTitle:@"Attachment"];
    } else if ([[segue identifier] isEqualToString:@"observationEditSegue"]) {
        self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style: UIBarButtonItemStylePlain target:nil action:nil];
        ObservationEditViewController *vc = [segue destinationViewController];
        [vc setObservation:_observation];
    }
}


@end

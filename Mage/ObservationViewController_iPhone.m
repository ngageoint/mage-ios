//
//  ObservationViewController_iPhone.m
//  MAGE
//
//  Created by Dan Barela on 2/11/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationViewController_iPhone.h"
#import "Observations.h"
#import "ObservationPropertyTableViewCell.h"
#import <Server+helper.h>
#import "ObservationHeaderTableViewCell.h"
#import "ImageViewerViewController.h"
#import "ObservationEditViewController.h"
#import "ObservationHeaderAttachmentTableViewCell.h"

@interface ObservationViewController_iPhone()

@property (strong, nonatomic) NSMutableArray *tableLayout;

@end

@implementation ObservationViewController_iPhone

- (void)viewWillAppear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillAppear:animated];
    
    NSString *name = [_observation.properties valueForKey:@"type"];
    self.navigationItem.title = name;
    
    self.tableLayout = [[NSMutableArray alloc] init];
    NSArray *headerSection = [[NSArray alloc] initWithObjects:@"observation-header", @"observation-map", @"observation-map-directions", nil];
    NSArray *attachmentSection = [[NSArray alloc] initWithObjects:@"observation-attachments", nil];
    [self.tableLayout addObject:headerSection];
    if (_observation.attachments.count != 0) {
        [self.tableLayout addObject:attachmentSection];
    }
    
    self.propertyTable.delegate = self;
    self.propertyTable.dataSource = self;
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

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return self.tableLayout.count + 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section < self.tableLayout.count) {
        return [(NSArray *)self.tableLayout[section] count];
    } else {
        return [_observation.properties count];
    }
}

- (void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == self.tableLayout.count) {
        ObservationPropertyTableViewCell *observationCell = (ObservationPropertyTableViewCell *) cell;
        id value = [[_observation.properties allObjects] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]];
        id title = [observationCell.fieldDefinition objectForKey:@"title"];
        if (title == nil) {
            title = [[_observation.properties allKeys] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]];
        }
        [observationCell populateCellWithKey:title andValue:value];
    }
}

- (ObservationPropertyTableViewCell *) cellForObservationAtIndex: (NSIndexPath *) indexPath inTableView: (UITableView *) tableView {
    id key = [[_observation.properties allKeys] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]];
    NSDictionary *form = [Server observationForm];
    
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
    
    if (indexPath.section < self.tableLayout.count) {
        ObservationHeaderTableViewCell *cell = (ObservationHeaderTableViewCell *)[tableView dequeueReusableCellWithIdentifier:self.tableLayout[indexPath.section][indexPath.row]];
        [cell configureCellForObservation:_observation];
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

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section < self.tableLayout.count) {
        ObservationHeaderTableViewCell *cell = (ObservationHeaderTableViewCell *)[tableView dequeueReusableCellWithIdentifier:self.tableLayout[indexPath.section][indexPath.row]];
        return cell.bounds.size.height;
    } else {
        ObservationPropertyTableViewCell *cell = [self cellForObservationAtIndex:indexPath inTableView:tableView];
        return [cell getCellHeightForValue:[[_observation.properties allObjects] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]]];
    }
    return 0.0;
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

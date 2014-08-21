//
//  ObservationEditViewController.m
//  Mage
//
//  Created by Dan Barela on 8/19/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationEditViewController.h"
#import "ObservationEditTableViewCell.h"
#import "DropdownEditTableViewController.h"
#import "ObservationPickerTableViewCell.h"
#import "DatePickerViewController.h"
#import "ObservationDatePickerTableViewCell.h"

@interface ObservationEditViewController ()

@property (weak, nonatomic) IBOutlet UITableView *editTable;
@property (nonatomic, strong) NSDateFormatter *dateDisplayFormatter;
@property (nonatomic, strong) NSDateFormatter *dateParseFormatter;
@end

@implementation ObservationEditViewController

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *form = [defaults objectForKey:@"form"];
    //id fields = [form objectForKey: @"fields"];
    return ((NSArray *)[form objectForKey:@"fields"]).count;
}

//- (void) configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
//	ObservationEditTableViewCell *observationCell = (ObservationEditTableViewCell *) cell;
//    id value = [[_observation.properties allObjects] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]];
//    id title = [observationCell.fieldDefinition objectForKey:@"title"];
//    if (title == nil) {
//        
//        title = [[_observation.properties allKeys] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]];
//        //        [_propertyTable deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:NO];
//    }
//    [observationCell populateCellWithKey:title andValue:value];
//}
//
//- (ObservationEditTableViewCell *) cellForObservationAtIndex: (NSIndexPath *) indexPath inTableView: (UITableView *) tableView {
//    id key = [[_observation.properties allKeys] objectAtIndex:[indexPath indexAtPosition:[indexPath length]-1]];
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    NSDictionary *form = [defaults objectForKey:@"form"];
//    
//    for (id field in [form objectForKey:@"fields"]) {
//        NSString *fieldName = [field objectForKey:@"name"];
//        if ([key isEqualToString: fieldName]) {
//            NSString *type = [field objectForKey:@"type"];
//            NSString *CellIdentifier = [NSString stringWithFormat:@"observationCell-%@", type];
//            ObservationPropertyTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//            if (cell == nil) {
//                CellIdentifier = @"observationCell-generic";
//                cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
//            }
//            cell.fieldDefinition = field;
//            return cell;
//        }
//    }
//    
//    NSString *CellIdentifier = @"observationEdit-generic";
//    ObservationEditTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
////    cell.fieldDefinition = field;
//    return cell;
//}

- (ObservationEditTableViewCell *) cellForFieldAtIndex: (NSIndexPath *) indexPath inTableView: (UITableView *) tableView {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *form = [defaults objectForKey:@"form"];
    id field = ((NSArray *)[form objectForKey:@"fields"])[indexPath.row];
    NSString *cellType = [NSString stringWithFormat:@"observationEdit-%@", [field objectForKey:@"type"]];
    ObservationEditTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellType];
    if (cell == nil) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"observationEdit-generic"];
    }
    cell.fieldDefinition = field;
    [cell populateCellWithFormField:field andObservation:_observation];
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ObservationEditTableViewCell *cell = [self cellForFieldAtIndex:indexPath inTableView:tableView];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    ObservationEditTableViewCell *cell = [self cellForFieldAtIndex:indexPath inTableView:tableView];
    return [cell getCellHeightForValue:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView beginUpdates];

    ObservationEditTableViewCell *cell = (ObservationEditTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    [cell selectRow];
    
    [tableView endUpdates];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"dropdownSegue"]) {
        DropdownEditTableViewController *vc = [segue destinationViewController];
        ObservationPickerTableViewCell *cell = sender;
        
        [vc setFieldDefinition:cell.fieldDefinition];
        [vc setValue:cell.valueLabel.text];
    } else if ([segue.identifier isEqualToString:@"datePickerSegue"]) {
        DatePickerViewController *dpvc = [segue destinationViewController];
        ObservationDatePickerTableViewCell *dpCell = sender;
        [dpvc setFieldDefinition:dpCell.fieldDefinition];
        [dpvc setValue:[_observation.properties objectForKey:(NSString *)[dpCell.fieldDefinition objectForKey:@"name"]]];
    }
}

- (IBAction)unwindFromDropdownController: (UIStoryboardSegue *) segue {
    DropdownEditTableViewController *vc = [segue sourceViewController];
    NSString *fieldKey = (NSString *)[vc.fieldDefinition objectForKey:@"name"];
    NSMutableDictionary *newProperties = [[NSMutableDictionary alloc] initWithDictionary:_observation.properties];
    [newProperties setObject:vc.value forKey:fieldKey];
    _observation.properties = newProperties;
    
    [self.editTable reloadData];
    NSLog(@"choose %@", vc.value);
    
}

- (IBAction)unwindFromDatePickerController: (UIStoryboardSegue *) segue {
    DatePickerViewController *vc = [segue sourceViewController];
    NSString *fieldKey = (NSString *)[vc.fieldDefinition objectForKey:@"name"];
    NSMutableDictionary *newProperties = [[NSMutableDictionary alloc] initWithDictionary:_observation.properties];
    [newProperties setObject:vc.value forKey:fieldKey];
    _observation.properties = newProperties;
    
    [self.editTable reloadData];
    NSLog(@"choose %@", vc.value);
    
}


@end

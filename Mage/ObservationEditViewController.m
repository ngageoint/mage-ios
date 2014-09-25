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
#import "DatePickerTableViewCell.h"
#import "ObservationDatePickerTableViewCell.h"

@interface ObservationEditViewController ()

@property (weak, nonatomic) IBOutlet UITableView *editTable;
@property (nonatomic, strong) NSDateFormatter *dateDisplayFormatter;
@property (nonatomic, strong) NSDateFormatter *dateParseFormatter;
@end

@implementation ObservationEditViewController

NSArray *_rowToCellType;
NSArray *_rowToField;
NSInteger expandedRow = -1;

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

- (NSArray *)rowToCellType {
    if (_rowToCellType != nil) {
        return _rowToCellType;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *form = [defaults objectForKey:@"form"];
    
    NSMutableArray *cells = [[NSMutableArray alloc] init];
    NSMutableArray *fields = [[NSMutableArray alloc] init];
    // run through the form and map the row indexes to fields
    for (id field in [form objectForKey:@"fields"]) {
        NSString *type = [field objectForKey:@"type"];
        [cells addObject:[NSString stringWithFormat: @"observationEdit-%@", type]];
        [fields addObject:field];
        if ([type isEqualToString:@"date"]) {
            [cells addObject:@"observationEdit-dateSpinner"];
            [fields addObject:field];
        }
    }
    _rowToCellType = cells;
    _rowToField = fields;
    
    return _rowToCellType;
}

- (NSArray *) rowToField {
    if (_rowToField != nil) {
        return _rowToField;
    }
    [self rowToCellType];
    return _rowToField;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self rowToField].count;
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
    NSString *cellType = (NSString *)[self rowToCellType][indexPath.row];
    id field = [self rowToField][indexPath.row];
    
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
    cell.delegate = self;
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    ObservationEditTableViewCell *cell = [self cellForFieldAtIndex:indexPath inTableView:tableView];
    if ([[[self rowToCellType] objectAtIndex: indexPath.row] isEqualToString:@"observationEdit-dateSpinner"]) {
        return [cell getCellHeightForValue:[NSNumber numberWithBool:(expandedRow == indexPath.row)]];
    }
    return [cell getCellHeightForValue:nil];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView beginUpdates];

    if ([[[[self rowToField] objectAtIndex:indexPath.row] objectForKey:@"type"] isEqualToString:@"date"]) {
        
        if (expandedRow != indexPath.row +1) {
            expandedRow = indexPath.row + 1;
        } else {
            expandedRow = -1;
        }
    }
    
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

- (void) observationField:(id)field valueChangedTo:(id)value {
    NSString *fieldKey = (NSString *)[field objectForKey:@"name"];
    NSMutableDictionary *newProperties = [[NSMutableDictionary alloc] initWithDictionary:_observation.properties];
    [newProperties setObject:value forKey:fieldKey];
    _observation.properties = newProperties;
    
    [self.editTable reloadData];
    NSLog(@"choose %@", value);

}


@end

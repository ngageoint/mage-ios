//
//  FilterTableViewController.m
//  MAGE
//
//  Created by William Newman on 10/31/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "LocationFilterTableViewController.h"
#import "TimeFilter.h"
#import "Theme+UIResponder.h"
#import "ObservationTableHeaderView.h"
#import "MAGE-Swift.h"

@interface LocationFilterTableViewController ()
@property (assign, nonatomic) TimeFilterType timeFilter;
@property (assign, nonatomic) TimeUnit customTimeUnit;
@property (assign, nonatomic) NSInteger customTimeNumber;
@property (assign, nonatomic) BOOL isPopover;
@property (weak, nonatomic) IBOutlet UILabel *customLabel;
@property (weak, nonatomic) IBOutlet UILabel *customDescription;
@property (weak, nonatomic) IBOutlet UILabel *lastLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *periodSegmentedControl;
@property (weak, nonatomic) IBOutlet UITextField *timeNumberTextField;

@end

@implementation LocationFilterTableViewController

- (void) themeDidChange:(MageTheme)theme {
    self.view.backgroundColor = [UIColor background];
    self.tableView.backgroundColor = [UIColor tableBackground];
    self.navigationController.navigationBar.barTintColor = [UIColor primary];
    self.customLabel.textColor = [UIColor primaryText];
    self.customDescription.textColor = [UIColor secondaryText];
    self.lastLabel.textColor = [UIColor primaryText];
    self.timeNumberTextField.textColor = [UIColor primaryText];
    self.timeNumberTextField.layer.borderWidth = .5f;
    self.timeNumberTextField.layer.borderColor = [[UIColor secondaryText] CGColor];
    self.periodSegmentedControl.tintColor = [UIColor brand];
    
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerForThemeChanges];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.timeFilter = [TimeFilter getLocationTimeFilter];
    self.customTimeUnit = [TimeFilter getLocationCustomTimeFilterUnit];
    self.customTimeNumber = [TimeFilter getLocationCustomTimeFilterNumber];
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = self.timeFilter == [indexPath row] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    cell.textLabel.textColor = [UIColor primaryText];
    cell.detailTextLabel.textColor = [UIColor secondaryText];
    cell.backgroundColor = [UIColor background];
    
    if ([indexPath row] == 5) {
        UISegmentedControl *timeUnitControl = (UISegmentedControl *) [cell viewWithTag:300];
        UITextField *timeNumberField = (UITextField *) [cell viewWithTag:200];
        
        timeUnitControl.selectedSegmentIndex = self.customTimeUnit;
        timeNumberField.text = [NSString stringWithFormat:@"%ld", (long)self.customTimeNumber];
    }
    
    return cell;
}

- (void)tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    UITableViewCell *selectedCell = [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.timeFilter inSection:0]];
    selectedCell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    self.timeFilter = [indexPath row];
    
    [self applyFilter];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *name = [self tableView:tableView titleForHeaderInSection:section];
    
    return [[ObservationTableHeaderView alloc] initWithName:name andScheme:[MAGEScheme scheme]];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 5 && self.timeFilter == TimeFilterCustom) {
        return 88.0;
    }
    return UITableViewAutomaticDimension;
}

- (void) applyFilter {
    if ([TimeFilter getLocationTimeFilter] != self.timeFilter) {
        [TimeFilter setLocationTimeFilter:self.timeFilter];
    }
    if ([TimeFilter getLocationCustomTimeFilterUnit] != self.customTimeUnit) {
        [TimeFilter setLocationCustomTimeFilterUnit:self.customTimeUnit];
    }
    if ([TimeFilter getLocationCustomTimeFilterNumber] != self.customTimeNumber) {
        [TimeFilter setLocationCustomTimeFilterNumber:self.customTimeNumber];
    }
}

- (IBAction)customTimeNumberEdited:(id)sender {
    UITextField *customTimeNumberField = (UITextField *) sender;
    self.customTimeNumber = [customTimeNumberField.text integerValue];
    [self applyFilter];
}

- (IBAction)customTimeUnitChanged:(id)sender {
    UISegmentedControl *customTimeUnitControl = (UISegmentedControl *) sender;
    self.customTimeUnit = customTimeUnitControl.selectedSegmentIndex;
    [self applyFilter];
}

- (IBAction)onApplyFilterTapped:(id)sender {
    [self applyFilter];
    
    if ([self.navigationController.viewControllers count] == 1) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end

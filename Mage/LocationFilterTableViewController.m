//
//  FilterTableViewController.m
//  MAGE
//
//  Created by William Newman on 10/31/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "LocationFilterTableViewController.h"
#import "TimeFilter.h"
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
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@end

@implementation LocationFilterTableViewController

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }
    self.view.backgroundColor = self.scheme.colorScheme.backgroundColor;
    self.tableView.backgroundColor = self.scheme.colorScheme.backgroundColor;
    self.customLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
    self.customDescription.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
    self.lastLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
    self.timeNumberTextField.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
    self.timeNumberTextField.layer.borderWidth = .5f;
    self.timeNumberTextField.layer.borderColor = [[self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6] CGColor];
    self.periodSegmentedControl.selectedSegmentTintColor = self.scheme.colorScheme.primaryColor;
    [self.periodSegmentedControl setTitleTextAttributes:@{
        NSForegroundColorAttributeName: [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6]
    } forState:UIControlStateNormal];
    [self.periodSegmentedControl setTitleTextAttributes:@{
        NSForegroundColorAttributeName: self.scheme.colorScheme.onPrimaryColor
    } forState:UIControlStateSelected];
    [self.tableView reloadData];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.timeFilter = [TimeFilter getLocationTimeFilter];
    self.customTimeUnit = [TimeFilter getLocationCustomTimeFilterUnit];
    self.customTimeNumber = [TimeFilter getLocationCustomTimeFilterNumber];
    [self applyThemeWithContainerScheme:self.scheme];
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = self.timeFilter == [indexPath row] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    if (self.scheme) {
        cell.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
        cell.detailTextLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
        cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
        cell.tintColor = self.scheme.colorScheme.primaryColorVariant;
    }
    
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
    
    return [[ObservationTableHeaderView alloc] initWithName:name andScheme:self.scheme];
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

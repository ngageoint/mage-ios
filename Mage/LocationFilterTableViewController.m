//
//  FilterTableViewController.m
//  MAGE
//
//  Created by William Newman on 10/31/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "LocationFilterTableViewController.h"
#import "TimeFilter.h"

@interface LocationFilterTableViewController ()
@property (assign, nonatomic) TimeFilterType timeFilter;
@property (assign, nonatomic) TimeUnit customTimeUnit;
@property (assign, nonatomic) NSInteger customTimeNumber;
@property (assign, nonatomic) BOOL isPopover;

@end

@implementation LocationFilterTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.timeFilter = [TimeFilter getLocationTimeFilter];
    self.customTimeUnit = [TimeFilter getLocationCustomTimeFilterUnit];
    self.customTimeNumber = [TimeFilter getLocationCustomTimeFilterNumber];
    
    
    self.isPopover = self.parentViewController.popoverPresentationController != nil;
    if (self.isPopover) {
        self.navigationController.navigationBarHidden = YES;
    }
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = self.timeFilter == [indexPath row] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    
    if ([indexPath row] == 5) {
        UISegmentedControl *timeUnitControl = (UISegmentedControl *) [cell viewWithTag:300];
        UITextField *timeNumberField = (UITextField *) [cell viewWithTag:200];
        
        timeUnitControl.selectedSegmentIndex = self.customTimeUnit;
        timeNumberField.text = [NSString stringWithFormat:@"%ld", self.customTimeNumber];
    }
    
    return cell;
}

- (void)tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    UITableViewCell *selectedCell = [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.timeFilter inSection:0]];
    selectedCell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    self.timeFilter = [indexPath row];
    
    if (self.isPopover) {
        [TimeFilter setLocationTimeFilter:self.timeFilter];
    }
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.row == 5 && self.timeFilter == TimeFilterCustom) {
        return 88.0;
    }
    return UITableViewAutomaticDimension;
}

- (IBAction)customTimeNumberEdited:(id)sender {
    UITextField *customTimeNumberField = (UITextField *) sender;
    self.customTimeNumber = [customTimeNumberField.text integerValue];
}

- (IBAction)customTimeUnitChanged:(id)sender {
    UISegmentedControl *customTimeUnitControl = (UISegmentedControl *) sender;
    self.customTimeUnit = customTimeUnitControl.selectedSegmentIndex;
}

- (IBAction)onApplyFilterTapped:(id)sender {
    [TimeFilter setLocationTimeFilter:self.timeFilter];
    [TimeFilter setLocationCustomTimeFilterUnit:self.customTimeUnit];
    [TimeFilter setLocationCustomTimeFilterNumber:self.customTimeNumber];
    
    if ([self.navigationController.viewControllers count] == 1) {
        [self dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

@end

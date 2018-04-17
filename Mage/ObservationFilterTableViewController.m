//
//  FilterTableViewController.m
//  MAGE
//
//  Created by William Newman on 10/31/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ObservationFilterTableViewController.h"
#import "TimeFilter.h"
#import "Observations.h"
#import "Theme+UIResponder.h"
#import "ObservationTableHeaderView.h"

@interface ObservationFilterTableViewController ()
@property (assign, nonatomic) TimeFilterType timeFilter;
@property (assign, nonatomic) BOOL importantFilter;
@property (assign, nonatomic) BOOL favoritesFilter;
@property (assign, nonatomic) TimeUnit customTimeUnit;
@property (assign, nonatomic) NSInteger customTimeNumber;
@property (assign, nonatomic) BOOL isPopover;
@property (weak, nonatomic) IBOutlet UILabel *favoritesLabel;
@property (weak, nonatomic) IBOutlet UILabel *favoritesDescription;
@property (weak, nonatomic) IBOutlet UISwitch *favoriteSwitch;
@property (weak, nonatomic) IBOutlet UILabel *importantLabel;
@property (weak, nonatomic) IBOutlet UILabel *importantDescription;
@property (weak, nonatomic) IBOutlet UISwitch *importantSwitch;
@property (weak, nonatomic) IBOutlet UILabel *customLabel;
@property (weak, nonatomic) IBOutlet UILabel *customDescription;
@property (weak, nonatomic) IBOutlet UILabel *lastLabel;
@property (weak, nonatomic) IBOutlet UISegmentedControl *periodSegmentedControl;
@property (weak, nonatomic) IBOutlet UITextField *timeNumberTextField;

@end

@implementation ObservationFilterTableViewController

- (void) themeDidChange:(MageTheme)theme {
    self.view.backgroundColor = [UIColor background];
    self.tableView.backgroundColor = [UIColor tableBackground];
    self.navigationController.navigationBar.barTintColor = [UIColor primary];
    self.favoritesLabel.textColor = [UIColor primaryText];
    self.importantLabel.textColor = [UIColor primaryText];
    self.favoritesDescription.textColor = [UIColor secondaryText];
    self.importantDescription.textColor = [UIColor secondaryText];
    self.customLabel.textColor = [UIColor primaryText];
    self.customDescription.textColor = [UIColor secondaryText];
    self.lastLabel.textColor = [UIColor primaryText];
    self.timeNumberTextField.textColor = [UIColor primaryText];
    self.timeNumberTextField.layer.borderWidth = .5f;
    self.timeNumberTextField.layer.borderColor = [[UIColor secondaryText] CGColor];
    self.periodSegmentedControl.tintColor = [UIColor brand];
    self.favoriteSwitch.onTintColor = [UIColor themedButton];
    self.importantSwitch.onTintColor = [UIColor themedButton];
    
    [self.tableView reloadData];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerForThemeChanges];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.timeFilter = [TimeFilter getObservationTimeFilter];
    self.importantFilter = [Observations getImportantFilter];
    self.favoritesFilter = [Observations getFavoritesFilter];
    self.customTimeUnit = [TimeFilter getObservationCustomTimeFilterUnit];
    self.customTimeNumber = [TimeFilter getObservationCustomTimeFilterNumber];
    
    self.navigationController.navigationBarHidden = NO;
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.textLabel.textColor = [UIColor primaryText];
    cell.detailTextLabel.textColor = [UIColor secondaryText];
    cell.backgroundColor = [UIColor background];
    
    if ([indexPath section] == 0) {
        UISwitch *switchControl = (UISwitch *) [cell viewWithTag:100];

        switch ([indexPath row]) {
            case 0:
                [switchControl setOn:self.favoritesFilter];
                break;
            case 1:
                [switchControl setOn:self.importantFilter];
                break;
        }
        // TODO change important/fav filter switches
    } else if ([indexPath section] == 1) {
        cell.accessoryType = self.timeFilter == [indexPath row] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
        
        if ([indexPath row] == 5) {
            UISegmentedControl *timeUnitControl = (UISegmentedControl *) [cell viewWithTag:300];
            UITextField *timeNumberField = (UITextField *) [cell viewWithTag:200];
            
            timeUnitControl.selectedSegmentIndex = self.customTimeUnit;
            timeNumberField.text = [NSString stringWithFormat:@"%ld", (long)self.customTimeNumber];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];

    if ([indexPath section] == 1) {
        UITableViewCell *selectedCell = [super tableView:tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:self.timeFilter inSection:1]];
        selectedCell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.timeFilter = [indexPath row];
        
        [self applyFilter];
        [self.tableView beginUpdates];
        [self.tableView endUpdates];
    }
}

- (UIView *) tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    NSString *name = [self tableView:tableView titleForHeaderInSection:section];
    
    return [[ObservationTableHeaderView alloc] initWithName:name];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 48.0f;
}

- (CGFloat) tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return CGFLOAT_MIN;
}

- (CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (indexPath.section == 1 && indexPath.row == 5 && self.timeFilter == TimeFilterCustom) {
        return 88.0;
    }
    return UITableViewAutomaticDimension;
}

- (void) applyFilter {
    if ([TimeFilter getObservationTimeFilter] != self.timeFilter) {
        [TimeFilter setObservationTimeFilter:self.timeFilter];
    }
    if ([Observations getImportantFilter] != self.importantFilter) {
        [Observations setImportantFilter:self.importantFilter];
    }
    if ([Observations getFavoritesFilter] != self.favoritesFilter) {
        [Observations setFavoritesFilter:self.favoritesFilter];
    }
    if ([TimeFilter getObservationCustomTimeFilterUnit] != self.customTimeUnit) {
        [TimeFilter setObservationCustomTimeFilterUnit:self.customTimeUnit];
    }
    if ([TimeFilter getObservationCustomTimeFilterNumber] != self.customTimeNumber) {
        [TimeFilter setObservationCustomTimeFilterNumber:self.customTimeNumber];
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

- (IBAction)onFavoritesFilterChanged:(UISwitch *)sender {
    self.favoritesFilter = [sender isOn];
    
    [self applyFilter];
}

- (IBAction)onImportantFilterChanged:(UISwitch *)sender {
    self.importantFilter = [sender isOn];
    
    [self applyFilter];
}

@end

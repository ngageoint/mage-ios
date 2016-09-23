//
//  FilterTableViewController.m
//  MAGE
//
//  Created by William Newman on 10/31/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "FilterTableViewController.h"
#import "TimeFilter.h"
#import "Observations.h"

@interface FilterTableViewController ()
@property (assign, nonatomic) TimeFilterType timeFilter;
@property (assign, nonatomic) BOOL importantFilter;
@property (assign, nonatomic) BOOL favoritesFilter;
@property (assign, nonatomic) BOOL isPopover;
@end

@implementation FilterTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.timeFilter = [TimeFilter getTimeFilter];
    self.importantFilter = [Observations getImportantFilter];
    self.favoritesFilter = [Observations getFavoritesFilter];
    
    self.isPopover = self.parentViewController.popoverPresentationController != nil;
    if (self.isPopover) {
        self.navigationController.navigationBarHidden = YES;
    }
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    
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
        
        if (self.isPopover) {
            [TimeFilter setTimeFilter:self.timeFilter];
        }
    }
}

- (IBAction)onApplyFilterTapped:(id)sender {
    [TimeFilter setTimeFilter:self.timeFilter];
    [Observations setImportantFilter:self.importantFilter];
    [Observations setFavoritesFilter:self.favoritesFilter];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onCancelFilterTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)onFavoritesFilterChanged:(UISwitch *)sender {
    self.favoritesFilter = [sender isOn];
    
    if (self.isPopover) {
        [Observations setFavoritesFilter:self.favoritesFilter];
    }
}

- (IBAction)onImportantFilterChanged:(UISwitch *)sender {
    self.importantFilter = [sender isOn];
    
    if (self.isPopover) {
        [Observations setImportantFilter:self.importantFilter];
    }
}

@end

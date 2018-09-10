//
//  LocationDisplayTableViewController.m
//  MAGE
//
//  Created by Dan Barela on 9/10/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "LocationDisplayTableViewController.h"
#import "NSDate+display.h"
#import "Theme+UIResponder.h"
#import "ObservationTableHeaderView.h"

@interface LocationDisplayTableViewController ()

@property (weak, nonatomic) IBOutlet UITableViewCell *latitudeLongitudeCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *mgrsCell;

@end

@implementation LocationDisplayTableViewController
- (void) themeDidChange:(MageTheme)theme {
    self.tableView.backgroundColor = [UIColor tableBackground];
    [self.tableView reloadData];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    [self registerForThemeChanges];
    if (@available(iOS 11.0, *)) {
        [self.navigationController.navigationBar setPrefersLargeTitles:NO];
    } else {
        // Fallback on earlier versions
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL showMGRS = [defaults boolForKey:@"showMGRS"];
    if (!showMGRS) {
        self.latitudeLongitudeCell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.mgrsCell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        self.latitudeLongitudeCell.accessoryType = UITableViewCellAccessoryNone;
        self.mgrsCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 1) {
        return 2;
    }
    return 0;
}

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor background];
    cell.textLabel.textColor = [UIColor primaryText];
    cell.detailTextLabel.textColor = [UIColor secondaryText];
    cell.tintColor = [UIColor flatButton];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    long row = [indexPath row];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (row == 0) {
        [defaults setBool:NO forKey:@"showMGRS"];
        self.latitudeLongitudeCell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.mgrsCell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        [defaults setBool:YES forKey:@"showMGRS"];
        self.latitudeLongitudeCell.accessoryType = UITableViewCellAccessoryNone;
        self.mgrsCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    [defaults synchronize];
    [tableView reloadData];
}

-(CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger) section {
    if (section == 0) {
        return 0.0001;
    }
    return 45.0;
}

-(UIView *) tableView:(UITableView*) tableView viewForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return [[UIView alloc] initWithFrame:CGRectZero];
    }
    
    return [[ObservationTableHeaderView alloc] initWithName:[self tableView:tableView titleForHeaderInSection:section]];
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView *tableViewHeaderFooterView = (UITableViewHeaderFooterView *) view;
        tableViewHeaderFooterView.textLabel.textColor  = [UIColor brand];
    }
}

@end

//
//  TimeSettingsTableViewController.m
//  MAGE
//
//  Created by Dan Barela on 3/10/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "TimeSettingsTableViewController.h"
#import "SettingsTableViewController.h"
#import "NSDate+display.h"
#import "Theme+UIResponder.h"
#import "ObservationTableHeaderView.h"

@interface TimeSettingsTableViewController ()

@property (weak, nonatomic) IBOutlet UITableViewCell *localTimeCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *gmtCell;

@end

@implementation TimeSettingsTableViewController

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
    BOOL gmtTimeZome = [defaults boolForKey:@"gmtTimeZome"];
    if (!gmtTimeZome) {
        self.localTimeCell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.gmtCell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        self.localTimeCell.accessoryType = UITableViewCellAccessoryNone;
        self.gmtCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    self.localTimeCell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [[NSTimeZone systemTimeZone] name]];
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
        [NSDate setDisplayGMT:NO];
        self.localTimeCell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.gmtCell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        [NSDate setDisplayGMT:YES];
        self.localTimeCell.accessoryType = UITableViewCellAccessoryNone;
        self.gmtCell.accessoryType = UITableViewCellAccessoryCheckmark;
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

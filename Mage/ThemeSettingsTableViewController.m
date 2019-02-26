//
//  ThemeSettingsTableViewController.m
//  MAGE
//
//  Created by Dan Barela on 3/27/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ThemeSettingsTableViewController.h"
#import "Theme+UIResponder.h"
#import "ObservationTableHeaderView.h"

@interface ThemeSettingsTableViewController ()

@end

@implementation ThemeSettingsTableViewController

static  NSString *THEME_CELL_REUSE_ID = @"THEME_CELL";

- (void) themeDidChange:(MageTheme)theme {
    self.view.backgroundColor = [UIColor background];
    self.tableView.backgroundColor = [UIColor tableBackground];
    [self.tableView reloadData];
}

-(void) viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeNever;

    [self registerForThemeChanges];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:THEME_CELL_REUSE_ID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:THEME_CELL_REUSE_ID];
    }
    
    cell.backgroundColor = [UIColor background];
    cell.textLabel.textColor = [UIColor primaryText];
    cell.tintColor = [UIColor flatButton];
    
    id<Theme> theme = [[ThemeManager sharedManager] themeDefinitionForTheme:indexPath.row];
    
    cell.textLabel.text = [theme displayName];
    if (indexPath.row == TheCurrentTheme) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [[ThemeManager sharedManager] setTheme:[NSNumber numberWithInteger:indexPath.row]];
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return NUM_THEMES;
}

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

@end

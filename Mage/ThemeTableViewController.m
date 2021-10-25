//
//  ThemeTableViewController.m
//  MAGE
//
//  Created by Daniel Barela on 10/25/21.
//  Copyright © 2021 National Geospatial Intelligence Agency. All rights reserved.
//

#import "ThemeTableViewController.h"
#import "ObservationTableHeaderView.h"
#import "DisplaySettingsHeader.h"
#import <MaterialComponents/MaterialContainerScheme.h>
#import "SettingsTableViewController.h"
#import "MAGE-Swift.h"

@interface ThemeTableViewController ()
@property (assign, nonatomic) NSInteger theme;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@property (strong, nonatomic) DisplaySettingsHeader *header;
@end

@implementation ThemeTableViewController

static NSString *THEME_DISPLAY_REUSE_ID = @"THEME_DISPLAY_REUSE_ID";
static NSString *THEME_DISPLAY_USER_DEFAULTS_KEY = @"themeOverride";

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }
    self.tableView.backgroundColor = self.scheme.colorScheme.backgroundColor;
    self.header.label.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent: 0.87];
    [self.tableView reloadData];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"Theme";
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.theme = [defaults integerForKey:THEME_DISPLAY_USER_DEFAULTS_KEY];
    
    self.header = [[NSBundle mainBundle] loadNibNamed:@"DisplaySettingsHeader" owner:self options:nil][0];
    self.header.label.text = [@"Override the system interface style for the MAGE application." uppercaseString];
    self.tableView.tableHeaderView = self.header;
}

- (void) viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    UIView *header = self.tableView.tableHeaderView;
    CGSize size = [header systemLayoutSizeFittingSize:CGSizeMake(header.frame.size.width, 0) withHorizontalFittingPriority:UILayoutPriorityRequired verticalFittingPriority:UILayoutPriorityFittingSizeLevel];
    if (header.frame.size.height != size.height) {
        CGRect frame = [header frame];
        frame.size.height = size.height;
        [header setFrame:frame];
        self.tableView.tableHeaderView = header;
        [self.tableView layoutIfNeeded];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:THEME_DISPLAY_REUSE_ID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:THEME_DISPLAY_REUSE_ID];
    }
    
    if (indexPath.row == UIUserInterfaceStyleUnspecified) {
        cell.textLabel.text = @"Follow system theme";
        cell.accessoryType = self.theme == UIUserInterfaceStyleUnspecified ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    } else if (indexPath.row == UIUserInterfaceStyleLight) {
        cell.textLabel.text = @"Light";
        cell.accessoryType = self.theme == UIUserInterfaceStyleLight ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    } else if (indexPath.row == UIUserInterfaceStyleDark) {
        cell.textLabel.text = @"Dark";
        cell.accessoryType = self.theme == UIUserInterfaceStyleDark ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    
    cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
    cell.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent: 0.87];
    cell.detailTextLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent: 0.6];
    cell.tintColor = self.scheme.colorScheme.primaryColor;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *unspecifiedCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:UIUserInterfaceStyleUnspecified inSection:0]];
    UITableViewCell *lightCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:UIUserInterfaceStyleLight inSection:0]];
    UITableViewCell *darkCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:UIUserInterfaceStyleDark inSection:0]];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (indexPath.row == UIUserInterfaceStyleUnspecified) {
        [defaults setInteger:UIUserInterfaceStyleUnspecified forKey:THEME_DISPLAY_USER_DEFAULTS_KEY];
        unspecifiedCell.accessoryType = UITableViewCellAccessoryCheckmark;
        lightCell.accessoryType = UITableViewCellAccessoryNone;
        darkCell.accessoryType = UITableViewCellAccessoryNone;
        [UIWindow followSystemColors];
    } else if (indexPath.row == UIUserInterfaceStyleLight) {
        [defaults setInteger:UIUserInterfaceStyleLight forKey:THEME_DISPLAY_USER_DEFAULTS_KEY];
        unspecifiedCell.accessoryType = UITableViewCellAccessoryNone;
        lightCell.accessoryType = UITableViewCellAccessoryCheckmark;
        darkCell.accessoryType = UITableViewCellAccessoryNone;
        [UIWindow forceLightMode];
    } else if (indexPath.row == UIUserInterfaceStyleDark) {
        [defaults setInteger:UIUserInterfaceStyleDark forKey:THEME_DISPLAY_USER_DEFAULTS_KEY];
        unspecifiedCell.accessoryType = UITableViewCellAccessoryNone;
        lightCell.accessoryType = UITableViewCellAccessoryNone;
        darkCell.accessoryType = UITableViewCellAccessoryCheckmark;
        [UIWindow forceDarkMode];
    }
    
    [defaults synchronize];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger) section {
    return 24.0;
}

@end

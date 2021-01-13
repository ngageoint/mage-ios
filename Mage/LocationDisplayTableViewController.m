//
//  LocationDisplayTableViewController.m
//  MAGE
//
//  Created by Dan Barela on 9/10/18.
//  Copyright © 2018 National Geospatial Intelligence Agency. All rights reserved.
//

#import "LocationDisplayTableViewController.h"
#import "NSDate+display.h"
#import "ObservationTableHeaderView.h"
#import "DisplaySettingsHeader.h"
#import <MaterialComponents/MaterialContainerScheme.h>

@interface LocationDisplayTableViewController ()
@property (assign, nonatomic) BOOL showMGRS;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;
@property (strong, nonatomic) DisplaySettingsHeader *header;
@end

@implementation LocationDisplayTableViewController

static NSString *LOCATION_DISPLAY_REUSE_ID = @"LOCATION_DISPLAY_REUSE_ID";
static NSString *LOCATION_DISPLAY_USER_DEFAULTS_KEY = @"showMGRS";
static NSInteger WGS84_CELL_ROW = 0;
static NSInteger MGRS_CELL_ROW = 1;

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

    self.header = [[NSBundle mainBundle] loadNibNamed:@"DisplaySettingsHeader" owner:self options:nil][0];
    self.header.label.text = [@"All locations in the app will be entered and displayed in either latitude, longitude or MGRS." uppercaseString];
    self.tableView.tableHeaderView = self.header;
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.showMGRS = [defaults boolForKey:LOCATION_DISPLAY_USER_DEFAULTS_KEY];
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
    return 2;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 24.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:LOCATION_DISPLAY_REUSE_ID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:LOCATION_DISPLAY_REUSE_ID];
    }
    
    if (indexPath.row == WGS84_CELL_ROW) {
        cell.textLabel.text = @"Latitude, Longitude";
        cell.accessoryType = self.showMGRS ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
    } else {
        cell.textLabel.text = @"MGRS";
        cell.accessoryType = self.showMGRS ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    
    cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
    cell.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent: 0.87];
    cell.detailTextLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent: 0.6];
    cell.tintColor = self.scheme.colorScheme.primaryColor;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *wgs84Cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:WGS84_CELL_ROW inSection:0]];
    UITableViewCell *mgrs4Cell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:MGRS_CELL_ROW inSection:0]];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (indexPath.row == WGS84_CELL_ROW) {
        [defaults setBool:NO forKey:LOCATION_DISPLAY_USER_DEFAULTS_KEY];
        wgs84Cell.accessoryType = UITableViewCellAccessoryCheckmark;
        mgrs4Cell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        [defaults setBool:YES forKey:LOCATION_DISPLAY_USER_DEFAULTS_KEY];
        wgs84Cell.accessoryType = UITableViewCellAccessoryNone;
        mgrs4Cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    [defaults synchronize];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

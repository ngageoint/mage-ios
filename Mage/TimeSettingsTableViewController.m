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
#import "DisplaySettingsHeader.h"

@interface TimeSettingsTableViewController ()
@property (assign, nonatomic) BOOL gmtTime;
@end

@implementation TimeSettingsTableViewController

static NSString *TIME_DISPLAY_REUSE_ID = @"TIME_DISPLAY_REUSE_ID";
static NSString *TIME_DISPLAY_USER_DEFAULTS_KEY = @"gmtTimeZome";
static NSInteger LOCAL_TIME_CELL_ROW = 0;
static NSInteger GMT_TIME_CELL_ROW = 1;

- (void) viewDidLoad {
    [super viewDidLoad];
    [self.navigationController.navigationBar setPrefersLargeTitles:NO];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.gmtTime = [defaults boolForKey:TIME_DISPLAY_USER_DEFAULTS_KEY];
    
    DisplaySettingsHeader *header = [[NSBundle mainBundle] loadNibNamed:@"DisplaySettingsHeader" owner:self options:nil][0];
    header.label.text = [@"All times in the app will be entered and displayed in either the local time zone or GMT." uppercaseString];
    self.tableView.tableHeaderView = header;
    
    [self registerForThemeChanges];
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

- (void) themeDidChange:(MageTheme)theme {
    self.tableView.backgroundColor = [UIColor tableBackground];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:TIME_DISPLAY_REUSE_ID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:TIME_DISPLAY_REUSE_ID];
    }
    
    if (indexPath.row == LOCAL_TIME_CELL_ROW) {
        cell.textLabel.text = @"Local Time";
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", [[NSTimeZone systemTimeZone] name]];
        cell.accessoryType = self.gmtTime ? UITableViewCellAccessoryNone : UITableViewCellAccessoryCheckmark;
    } else {
        cell.textLabel.text = @"GMT";
        cell.detailTextLabel.text = @"";
        cell.accessoryType = self.gmtTime ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    
    cell.backgroundColor = [UIColor background];
    cell.textLabel.textColor = [UIColor primaryText];
    cell.detailTextLabel.textColor = [UIColor secondaryText];
    cell.tintColor = [UIColor flatButton];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *localCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:LOCAL_TIME_CELL_ROW inSection:0]];
    UITableViewCell *gmtCell = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:GMT_TIME_CELL_ROW inSection:0]];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (indexPath.row == LOCAL_TIME_CELL_ROW) {
        [NSDate setDisplayGMT:NO];
        localCell.accessoryType = UITableViewCellAccessoryCheckmark;
        gmtCell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        [NSDate setDisplayGMT:YES];
        localCell.accessoryType = UITableViewCellAccessoryNone;
        gmtCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    [defaults synchronize];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

-(CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger) section {
    return 24.0;
}

@end

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

@interface TimeSettingsTableViewController ()

@property (weak, nonatomic) IBOutlet UITableViewCell *localTimeCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *gmtCell;

@end

@implementation TimeSettingsTableViewController

- (void) viewDidLoad {
    [super viewDidLoad];
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

@end

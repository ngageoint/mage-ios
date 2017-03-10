//
//  TimeSettingsTableViewController.m
//  MAGE
//
//  Created by Dan Barela on 3/10/17.
//  Copyright © 2017 National Geospatial Intelligence Agency. All rights reserved.
//

#import "TimeSettingsTableViewController.h"

@interface TimeSettingsTableViewController ()

@property (weak, nonatomic) IBOutlet UITableViewCell *localTimeCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *gmtCell;

@end

@implementation TimeSettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL localTime = [defaults boolForKey:@"localTimeZome"];
    if (localTime) {
        self.localTimeCell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.gmtCell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        self.localTimeCell.accessoryType = UITableViewCellAccessoryNone;
        self.gmtCell.accessoryType = UITableViewCellAccessoryCheckmark;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    long row = [indexPath row];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (row == 0) {
        [defaults setBool:YES forKey:@"localTimeZone"];
        self.localTimeCell.accessoryType = UITableViewCellAccessoryCheckmark;
        self.gmtCell.accessoryType = UITableViewCellAccessoryNone;
    } else {
        [defaults setBool:NO forKey:@"localTimeZone"];
        self.localTimeCell.accessoryType = UITableViewCellAccessoryNone;
        self.gmtCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    [defaults synchronize];
    [tableView reloadData];

}

@end

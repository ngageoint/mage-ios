//
//  UserTableViewController.m
//  MAGE
//
//  Created by William Newman on 11/14/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "UserTableViewController.h"
#import "MeViewController.h"

@interface UserTableViewController ()

@end

@implementation UserTableViewController

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.userDataStore startFetchControllerForUserIds:self.userIds];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void) prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    if ([segue.identifier isEqualToString:@"ShowUserSegue"]) {
        id destination = [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
        
        User *user = [self.userDataStore.fetchedResultsController objectAtIndexPath:indexPath];
        [destination setUser:user];
    }
}


@end

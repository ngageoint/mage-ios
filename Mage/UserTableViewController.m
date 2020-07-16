//
//  UserTableViewController.m
//  MAGE
//
//  Created by William Newman on 11/14/16.
//  Copyright © 2016 National Geospatial Intelligence Agency. All rights reserved.
//

#import "UserTableViewController.h"
#import "MeViewController.h"
#import "MAGE-Swift.h"

@interface UserTableViewController () <UserSelectionDelegate>

@end

@implementation UserTableViewController

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.userDataStore) {
        self.userDataStore = [[UserDataStore alloc] init];
        self.userDataStore.tableView = self.tableView;
        self.tableView.dataSource = self.userDataStore;
        self.tableView.delegate = self.userDataStore;
    }
    self.userDataStore.userSelectionDelegate = self;
    [self.userDataStore startFetchControllerForUserIds:self.userIds];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"PersonCell" bundle:nil] forCellReuseIdentifier:@"personCell"];
    
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void) prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    if ([segue.identifier isEqualToString:@"ShowUserSegue"]) {
        id destination = [segue destinationViewController];        
        User *user = (User *)sender;
        [destination setUser:user];
    }
}

- (void) userDetailSelected:(User *)user {
    UserViewController *uvc = [[UserViewController alloc] initWithUser:user];
    [self.navigationController pushViewController:uvc animated:YES];
//    [self performSegueWithIdentifier:@"ShowUserSegue" sender:user];
}

- (void) selectedUser:(User *)user {
    UserViewController *uvc = [[UserViewController alloc] initWithUser:user];
    [self.navigationController pushViewController:uvc animated:YES];
//    [self performSegueWithIdentifier:@"ShowUserSegue" sender:user];
}

- (void) selectedUser:(User *)user region:(MKCoordinateRegion)region {
    UserViewController *uvc = [[UserViewController alloc] initWithUser:user];
    [self.navigationController pushViewController:uvc animated:YES];
//    [self performSegueWithIdentifier:@"ShowUserSegue" sender:user];
}


@end

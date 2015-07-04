//
//  LocationContainerViewController.m
//  MAGE
//
//  Created by William Newman on 7/3/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
//

#import "PeopleContainerViewController.h"
#import "PeopleTableViewController.h"

@interface PeopleContainerViewController ()

@end

@implementation PeopleContainerViewController

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString: @"PeopleTableViewControllerSegue"]) {
        PeopleTableViewController *peopleTableViewController = (PeopleTableViewController *) [segue destinationViewController];
        peopleTableViewController.peopleDataStore.personSelectionDelegate = self.delegate;
    }
}

@end

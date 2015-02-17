//
//  PeopleViewController.m
//  Mage
//
//  Created by Billy Newman on 7/14/14.
//

#import "PeopleTableViewController.h"
#import "Location.h"
#import "MeViewController.h"

@implementation PeopleTableViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.peopleDataStore startFetchController];
}

- (void) prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    if ([[segue identifier] isEqualToString:@"DisplayPersonSegue"]) {
        MeViewController *destination = (MeViewController *)[segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
		Location *location = [self.peopleDataStore locationAtIndexPath:indexPath];
		[destination setUser:location.user];
    }
}


@end

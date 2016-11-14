//
//  LocationContainerViewController.m
//  MAGE
//
//

#import "PeopleContainerViewController.h"
#import "LocationTableViewController.h"

@interface PeopleContainerViewController ()

@end

@implementation PeopleContainerViewController

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString: @"PeopleTableViewControllerSegue"]) {
        LocationTableViewController *locationTableViewController = (LocationTableViewController *) [segue destinationViewController];
        locationTableViewController.locationDataStore.personSelectionDelegate = self.delegate;
    }
}

@end

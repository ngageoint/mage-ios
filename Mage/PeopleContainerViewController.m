//
//  LocationContainerViewController.m
//  MAGE
//
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

//
//  ObservationContainerViewController.m
//  MAGE
//
//

#import "ObservationContainerViewController.h"
#import "ObservationTableViewController.h"

@interface ObservationContainerViewController ()

@end

@implementation ObservationContainerViewController

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString: @"ObservationTableViewControllerSegue"]) {
        ObservationTableViewController *observationTableViewController = (ObservationTableViewController *) [segue destinationViewController];
        observationTableViewController.attachmentDelegate = self.delegate;
        observationTableViewController.observationDataStore.observationSelectionDelegate = self.delegate;
    }
}


@end

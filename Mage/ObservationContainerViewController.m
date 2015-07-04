//
//  ObservationContainerViewController.m
//  MAGE
//
//  Created by William Newman on 7/3/15.
//  Copyright (c) 2015 National Geospatial Intelligence Agency. All rights reserved.
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

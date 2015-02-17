//
//  ObservationsViewController.m
//  Mage
//
//  Created by Dan Barela on 4/29/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "ObservationTableViewController.h"
#import "ObservationTableViewCell.h"
#import <Observation.h>
#import "ObservationViewController.h"
#import "MageRootViewController.h"
#import "AttachmentSelectionDelegate.h"
#import "ImageViewerViewController.h"

@interface ObservationTableViewController () <AttachmentSelectionDelegate>
@property(nonatomic, strong) IBOutlet UIRefreshControl *refreshControl;
@end

@implementation ObservationTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.observationDataStore startFetchController];
    
    [self.refreshControl addTarget:self
                            action:@selector(refreshObservations)
                  forControlEvents:UIControlEventValueChanged];
}

- (void) prepareForSegue:(UIStoryboardSegue *) segue sender:(id) sender {
    if ([[segue identifier] isEqualToString:@"DisplayObservationSegue"]) {
        id destination = [segue destinationViewController];
        NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
		Observation *observation = [self.observationDataStore observationAtIndexPath:indexPath];
		[destination setObservation:observation];
    } else if ([[segue identifier] isEqualToString:@"viewImageSegue"]) {
        // Get reference to the destination view controller
        ImageViewerViewController *vc = [segue destinationViewController];
        [vc setAttachment:sender];
    }
}

-(void) refreshObservations {
    NSLog(@"refreshObservations");
}

- (void) selectedAttachment:(Attachment *)attachment {
    NSLog(@"attachment selected");
    if (self.attachmentDelegate != nil) {
        [self.attachmentDelegate selectedAttachment:attachment];
    } else {
        [self performSegueWithIdentifier:@"viewImageSegue" sender:attachment];
    }
}

@end

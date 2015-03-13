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
#import <Event+helper.h>
#import <User+helper.h>
#import "ObservationEditViewController.h"
#import <LocationService.h>

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
    } else if ([segue.identifier isEqualToString:@"CreateNewObservationSegue"]) {
        ObservationEditViewController *editViewController = segue.destinationViewController;
        CLLocation *location = [[LocationService singleton] location];
        if (location != nil) {
            GeoPoint *point = [[GeoPoint alloc] initWithLocation:location];
            [editViewController setLocation:point];
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Location Unknown"
                                                            message:@"MAGE was unable to determine your location.  Please manually set the location of the new observation."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
        }
    }
}

- (BOOL) shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"CreateNewObservationSegue"] || [identifier isEqualToString:@"CreateNewObservationAtPointSegue"]) {
        if (![[Event getCurrentEvent] isUserInEvent:[User fetchCurrentUserInManagedObjectContext:[NSManagedObjectContext MR_defaultContext]]]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"You are not part of this event"
                                                            message:@"You cannot create observations for an event you are not part of."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            return false;
        }
    }
    return true;
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

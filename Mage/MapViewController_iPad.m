//
//  MapViewController_iPad.m
//  MAGE
//
//

#import "MapViewController_iPad.h"
#import "ObservationEditViewController.h"
#import <GeoPoint.h>
#import "LocationAnnotation.h"
#import "ObservationAnnotation.h"
#import <Location.h>
#import <Event.h>
#import "TimeFilter.h"

@interface MapViewController_iPad ()
@property (weak, nonatomic) IBOutlet UIBarButtonItem *moreButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *filterButton;
@end

@implementation MapViewController_iPad

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    
    UILabel *lblTitle = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 150, 20)];
    lblTitle.backgroundColor = [UIColor clearColor];
    lblTitle.textColor = [UIColor whiteColor];
    lblTitle.font = [UIFont boldSystemFontOfSize:18];
    lblTitle.textAlignment = NSTextAlignmentLeft;
    lblTitle.text = [Event getCurrentEvent].name;
    [lblTitle sizeToFit];
    
    [self.eventNameItem setCustomView:lblTitle];
}

- (void) viewDidDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO];
    [super viewDidDisappear:animated];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"CreateNewObservationSegue"]) {
        ObservationEditViewController *editViewController = segue.destinationViewController;
        
        CLLocation *location = [[CLLocation alloc] initWithLatitude:[self.mapView centerCoordinate].latitude longitude:[self.mapView centerCoordinate].longitude];
        GeoPoint *point = [[GeoPoint alloc] initWithLocation:location];
        
        [editViewController setLocation:point];
    } else {
        [super prepareForSegue:segue sender:sender];
    }
}

-(void) calloutTapped:(id) calloutItem {
    if ([calloutItem isKindOfClass:[User class]]) {
        [self userDetailSelected:(User *) calloutItem];
    } else if ([calloutItem isKindOfClass:[Observation class]]) {
        [self observationDetailSelected:(Observation *) calloutItem];
    }
}

- (void)selectedUser:(User *) user {
    [self.mapDelegate selectedUser:user];
}

- (void)selectedUser:(User *) user region:(MKCoordinateRegion) region {
    [self.mapDelegate selectedUser:user region:region];
}

- (void)selectedObservation:(Observation *) observation {
    [self.mapDelegate selectedObservation:observation];
}

- (void)selectedObservation:(Observation *) observation region:(MKCoordinateRegion) region {
    [self.mapDelegate selectedObservation:observation region:region];
}

- (void)observationDetailSelected:(Observation *)observation {
    [self.mapDelegate observationDetailSelected:observation];
    [self performSegueWithIdentifier:@"DisplayObservationSegue" sender:observation];
}

- (void)userDetailSelected:(User *)user {
    [self.mapDelegate userDetailSelected:user];
    [self performSegueWithIdentifier:@"DisplayPersonSegue" sender:user];
}

- (IBAction)moreTapped:(id)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"New Observation" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performSegueWithIdentifier:@"CreateNewObservationSegue" sender:self];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Filter" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performSegueWithIdentifier:@"FilterSegue" sender:self];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"My Profile" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performSegueWithIdentifier:@"DisplayPersonSegue" sender:nil];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Settings" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self performSegueWithIdentifier:@"SettingsSegue" sender:self];
    }]];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"Log out" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self performSegueWithIdentifier:@"unwindToInitial" sender:self];
    }]];
    
    alert.popoverPresentationController.barButtonItem = self.moreButton;

    [self presentViewController:alert animated:YES completion:nil];
}

@end

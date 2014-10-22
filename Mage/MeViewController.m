//
//  MeViewController.m
//  MAGE
//
//  Created by Dan Barela on 10/20/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "MeViewController.h"
#import "UIImage+Resize.h"
#import "ManagedObjectContextHolder.h"
#import "Observations.h"
#import <User+helper.h>
#import <MapKit/MapKit.h>
#import "Locations.h"
#import "MapDelegate.h"
#import <Location+helper.h>
#import "ObservationDataStore.h"
#import "ImageViewerViewController.h"

@interface MeViewController () <UIActionSheetDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *avatar;
@property (strong, nonatomic) IBOutlet ManagedObjectContextHolder *contextHolder;
@property (weak, nonatomic) IBOutlet MKMapView *map;
@property (strong, nonatomic) IBOutlet MapDelegate *mapDelegate;
@property (strong, nonatomic) IBOutlet ObservationDataStore *observationDataStore;
@property (weak, nonatomic) IBOutlet UILabel *name;
@property (weak, nonatomic) IBOutlet UILabel *username;

@end

@implementation MeViewController

- (void) viewDidLoad {
    
    if (self.user == nil) {
        self.user = [User fetchCurrentUserForManagedObjectContext: self.contextHolder.managedObjectContext];
    }
    
    self.name.text = self.user.name;
    self.username.text = self.user.username;
    
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];

    [self.avatar setImage:[UIImage imageWithData: [NSData dataWithContentsOfURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?access_token=%@",self.user.avatarUrl, [defaults objectForKey:@"token"]]]]]];
    
    Locations *locations = [Locations locationsForUser:self.user inManagedObjectContext:self.contextHolder.managedObjectContext];
    [self.mapDelegate setLocations:locations];
    
    Observations *observations = [Observations observationsForUser:self.user inManagedObjectContext:self.contextHolder.managedObjectContext];
    [self.observationDataStore startFetchControllerWithObservations:observations];
    [self.mapDelegate setObservations:observations];
}

- (IBAction)portraitClick:(id)sender {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil otherButtonTitles:@"View Avatar", @"Change Avatar", nil];
    [actionSheet showInView:self.view];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 0:
            // view avatar
            NSLog(@"view avatar");
            [self performSegueWithIdentifier:@"viewImageSegue" sender:self];
            break;
        case 1:
            // change avatar
            NSLog(@"change avatar");
            break;
        default:
            break;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
//    CLLocationDistance latitudeMeters = 500;
//    CLLocationDistance longitudeMeters = 500;
//    NSDictionary *properties = self.user.location.properties;
//    id accuracyProperty = [properties valueForKeyPath:@"accuracy"];
//    if (accuracyProperty != nil) {
//        double accuracy = [accuracyProperty doubleValue];
//        latitudeMeters = accuracy > latitudeMeters ? accuracy * 2.5 : latitudeMeters;
//        longitudeMeters = accuracy > longitudeMeters ? accuracy * 2.5 : longitudeMeters;
//    }
//    
//    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance([self.user.location location].coordinate, latitudeMeters, longitudeMeters);
//    MKCoordinateRegion viewRegion = [self.map regionThatFits:region];
//    
//    [self.mapDelegate selectedUser:self.user region:viewRegion];
}

- (IBAction)dismissMe:(id)sender {
    NSLog(@"Done");
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"viewImageSegue"]) {
        ImageViewerViewController *vc = [segue destinationViewController];
        NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
        [vc setImageUrl: [NSURL URLWithString:[NSString stringWithFormat:@"%@?access_token=%@",self.user.avatarUrl, [defaults objectForKey:@"token"]]]];
        
    }
}

@end

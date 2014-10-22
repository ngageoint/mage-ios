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

@interface MeViewController ()

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

@end

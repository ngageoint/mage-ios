//
//  SettingsViewController.m
//  Mage
//
//  Created by Dan Barela on 2/21/14.
//  Copyright (c) 2014 Dan Barela. All rights reserved.
//

#import "SettingsViewController.h"
#import "User+helper.h"
#import "LocationService.h"

@interface SettingsViewController ()

    @property (weak, nonatomic) IBOutlet UILabel *locationServicesStatus;
    @property (weak, nonatomic) IBOutlet UILabel *dataFetchStatus;
    @property (weak, nonatomic) IBOutlet UILabel *imageUploadSizeLabel;
    @property (weak, nonatomic) IBOutlet UILabel *user;
    @property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation SettingsViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    User *user = [User fetchCurrentUserForManagedObjectContext:_managedObjectContext];
    _user.text = [NSString stringWithFormat:@"%@ (%@)", user.name, user.username];
    
    [self setLocationServicesLabel];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[defaults objectForKey:@"dataFetchEnabled"] boolValue]) {
        [self.dataFetchStatus setText:@"On"];
    } else {
        [self.dataFetchStatus setText:@"Off"];
    }
    
    [self setPreferenceDisplayLabel:_imageUploadSizeLabel forPreference:@"imageUploadSizes"];
}

- (void) setLocationServicesLabel {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorized) {
        if ([defaults boolForKey:kReportLocationKey]) {
            [self.locationServicesStatus setText:@"On"];
        } else {
            [self.locationServicesStatus setText:@"Off"];
        }
    } else {
        [self.locationServicesStatus setText:@"Disabled"];
    }
}

- (void) setPreferenceDisplayLabel : (UILabel*) label forPreference: (NSString*) prefValuesKey {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    
    NSDictionary *frequencyDictionary = [defaults dictionaryForKey:prefValuesKey];
    NSArray *labels = [frequencyDictionary valueForKey:@"labels"];
    NSArray *values = [frequencyDictionary valueForKey:@"values"];
    
    NSNumber *frequency = [defaults valueForKey:[frequencyDictionary valueForKey:@"preferenceKey"]];
    
    for (int i = 0; i < values.count; i++) {
        if ([frequency integerValue] == [[values objectAtIndex:i] integerValue]) {
            [label setText:[labels objectAtIndex:i]];
            break;
        }
    }
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([segue.identifier hasPrefix:@"value_"]) {
        ValuePickerTableViewController *vc = [segue destinationViewController];
        NSDictionary *valueDictionary = [defaults dictionaryForKey:[segue.identifier substringFromIndex:6]];
        vc.title = [valueDictionary valueForKey:@"title"];
        vc.section = [valueDictionary valueForKey:@"section"];
        vc.labels = [valueDictionary valueForKey:@"labels"];
        vc.values = [valueDictionary valueForKey:@"values"];
        vc.preferenceKey = [valueDictionary valueForKey:@"preferenceKey"];
    }
}

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self setLocationServicesLabel];
}

@end

//
//  SettingsTableViewController_iPad.m
//  MAGE
//
//  Created by William Newman on 10/6/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "SettingsTableViewController_iPad.h"
#import "LocationService.h"
#import "User+helper.h"

@interface SettingsTableViewController_iPad ()

@property (weak, nonatomic) IBOutlet UILabel *locationServicesStatus;
@property (weak, nonatomic) IBOutlet UILabel *dataFetchStatus;
@property (weak, nonatomic) IBOutlet UILabel *imageUploadSizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *serverUrl;
@property (weak, nonatomic) IBOutlet UILabel *user;
@property (weak, nonatomic) IBOutlet UILabel *versionLabel;
@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation SettingsTableViewController_iPad

- (void) viewDidLoad {
    [super viewDidLoad];
    
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.versionLabel.text = [[NSBundle mainBundle] objectForInfoDictionaryKey: @"CFBundleShortVersionString"];

    User *user = [User fetchCurrentUserForManagedObjectContext:self.contextHolder.managedObjectContext];
    self.user.text = [NSString stringWithFormat:@"%@ (%@)", user.name, user.username];
    
    [self setLocationServicesLabel];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.serverUrl.text = [[defaults URLForKey:@"serverUrl"] absoluteString];
    
    if ([[defaults objectForKey:@"dataFetchEnabled"] boolValue]) {
        [self.dataFetchStatus setText:@"On"];
    } else {
        [self.dataFetchStatus setText:@"Off"];
    }
    
    [self setPreferenceDisplayLabel:_imageUploadSizeLabel forPreference:@"imageUploadSizes"];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
   if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            [self.settingSelectionDelegate selectedSetting:@"locationServicesSettings"];
        } else if (indexPath.row == 1) {
            [self.settingSelectionDelegate selectedSetting:@"dataFetchingSettings"];
        }
    } else if (indexPath.section == 2) {
        
    }
}

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self setLocationServicesLabel];
}

@end

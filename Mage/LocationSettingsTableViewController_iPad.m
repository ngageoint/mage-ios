//
//  LocationSettingsTableViewController_iPad.m
//  MAGE
//
//  Created by William Newman on 10/7/14.
//  Copyright (c) 2014 National Geospatial Intelligence Agency. All rights reserved.
//

#import "LocationSettingsTableViewController_iPad.h"
#import "LocationService.h"
#import "LocationTimeIntervalDataSource.h"

@interface LocationSettingsTableViewController_iPad ()

@property (weak, nonatomic) IBOutlet UISwitch *reportLocationSwitch;
@property (weak, nonatomic) IBOutlet UILabel *userReportingFrequencyLabel;
@property (weak, nonatomic) IBOutlet UILabel *gpsSensitivityLabel;
@property (weak, nonatomic) IBOutlet UIPickerView *timeIntervalPicker;
@property (weak, nonatomic) IBOutlet UIPickerView *gpsSensitivityPicker;

@property (nonatomic, weak) IBOutlet LocationTimeIntervalDataSource *locationIntervalDataSource;
@property (nonatomic, weak) IBOutlet GPSSensitivityDataSource *gpsSensitivityDataSource;

@property (strong, nonatomic) CLLocationManager *locationManager;

@property (nonatomic) BOOL isTimeIntervalSelected;
@property (nonatomic) BOOL isGPSSensitivitySelected;

@end

@implementation LocationSettingsTableViewController_iPad

- (IBAction) reportLocationChanged:(id)sender {
    BOOL isOn = [sender isOn];
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:2];
    
    if (isOn) {
        [self.tableView insertSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
    } else {
        [self.tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
    }
    
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    [defaults setBool:isOn forKey:kReportLocationKey];
    [defaults synchronize];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    [_reportLocationSwitch setOn:[[defaults objectForKey:kReportLocationKey] boolValue] animated:NO];
    
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self setPreferenceDisplayLabel:self.userReportingFrequencyLabel forPreference:@"userReporting"];
    [self setPreferenceDisplayLabel:self.gpsSensitivityLabel forPreference:@"gpsSensitivities"];
    
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    
    NSInteger timePickerRow = [[self.locationIntervalDataSource values] indexOfObject:[defaults objectForKey:kLocationReportingFrequencyKey]];
    [self.timeIntervalPicker selectRow:timePickerRow inComponent:0 animated:NO];
    
    NSInteger gpsPickerRow = [[self.gpsSensitivityDataSource values] indexOfObject:[defaults objectForKey:kGPSSensitivityKey]];
    [self.gpsSensitivityPicker selectRow:gpsPickerRow inComponent:0 animated:NO];
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    if (authorizationStatus == kCLAuthorizationStatusAuthorizedAlways || authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse) {
        return [_reportLocationSwitch isOn] ? 3 : 2;
    }
    
    return 1;
}

-(CGFloat)tableView:(UITableView*)tableView heightForHeaderInSection:(NSInteger) section {
    if (section == 1) {
        return .1f;
    }
    
    return UITableViewAutomaticDimension;
}

-(CGFloat)tableView:(UITableView*)tableView heightForFooterInSection:(NSInteger) section {
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    if (section == 0 && (authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse || authorizationStatus == kCLAuthorizationStatusAuthorizedAlways)) {
        return CGFLOAT_MIN;
    }
    
    return UITableViewAutomaticDimension;
}

-(UIView *) tableView:(UITableView*) tableView viewForFooterInSection:(NSInteger) section {
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    if (section == 0 && (authorizationStatus == kCLAuthorizationStatusAuthorizedAlways || authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse)) {
        return [[UIView alloc] initWithFrame:CGRectZero];
    }
    
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2) {
        if (indexPath.row == 0) {
            self.isTimeIntervalSelected = !self.isTimeIntervalSelected;
            [tableView reloadData];
        } else if (indexPath.row == 2) {
            self.isGPSSensitivitySelected = !self.isGPSSensitivitySelected;
            [tableView reloadData];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *) indexPath {
    if (indexPath.section == 2) {
        if (indexPath.row == 1 && !self.isTimeIntervalSelected) {
            return 0.0;
        } else if (indexPath.row == 3 && !self.isGPSSensitivitySelected) {
            return 0.0;
        }
    }
    
    CGFloat height = [super tableView:tableView heightForRowAtIndexPath:indexPath];
    return height;
}

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self.tableView reloadData];
}

-(void) gpsSensistivitySelected:(NSString *) value withLabel:(NSString *) label {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:kGPSSensitivityKey];
    [defaults synchronize];
    
    [self setPreferenceDisplayLabel:self.gpsSensitivityLabel forPreference:@"gpsSensitivities"];
}

-(void) locationIntervalSelected:(NSString *) value withLabel:(NSString *) label {
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    [defaults setObject:value forKey:kLocationReportingFrequencyKey];
    [defaults synchronize];
    
    [self setPreferenceDisplayLabel:self.userReportingFrequencyLabel forPreference:@"userReporting"];
}


@end

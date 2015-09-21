//
//  LocationServicesSettingsTableViewController.m
//  Mage
//
//

#import "LocationServicesSettingsTableViewController.h"
#import "LocationService.h"

@interface LocationServicesSettingsTableViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *reportLocationSwitch;
@property (weak, nonatomic) IBOutlet UILabel *userReportingFrequencyLabel;
@property (weak, nonatomic) IBOutlet UILabel *gpsSensitivityLabel;
@property (strong, nonatomic) CLLocationManager *locationManager;

@end

@implementation LocationServicesSettingsTableViewController

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    [_reportLocationSwitch setOn:[[defaults objectForKey:kReportLocationKey] boolValue] animated:NO];
    
    _locationManager = [[CLLocationManager alloc] init];
    _locationManager.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self setPreferenceDisplayLabel:self.userReportingFrequencyLabel forPreference:@"userReporting"];
    [self setPreferenceDisplayLabel:self.gpsSensitivityLabel forPreference:@"gpsSensitivities"];
}

- (void) setPreferenceDisplayLabel : (UILabel*) label forPreference: (NSString*) prefValuesKey
{
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

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied) {
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
    if (section == 0 && authorizationStatus != kCLAuthorizationStatusDenied) {
        return [[UIView alloc] initWithFrame:CGRectZero];
    }
    
    return nil;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
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
    [self.tableView reloadData];
}

@end

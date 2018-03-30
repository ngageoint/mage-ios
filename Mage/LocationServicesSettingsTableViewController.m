//
//  LocationServicesSettingsTableViewController.m
//  Mage
//
//

#import "LocationServicesSettingsTableViewController.h"
#import "LocationService.h"
#import "ObservationTableHeaderView.h"
#import "Theme+UIResponder.h"

@interface LocationServicesSettingsTableViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *reportLocationSwitch;
@property (weak, nonatomic) IBOutlet UILabel *userReportingFrequencyLabel;
@property (weak, nonatomic) IBOutlet UILabel *gpsSensitivityLabel;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (weak, nonatomic) IBOutlet UILabel *reportLocationlabel;
@property (weak, nonatomic) IBOutlet UILabel *reportLocationDescription;
@property (weak, nonatomic) IBOutlet UILabel *timeIntervalLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeIntervalDescription;
@property (weak, nonatomic) IBOutlet UILabel *gpsDistanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *gpsDistanceDescription;

@end

@implementation LocationServicesSettingsTableViewController

- (void) themeDidChange:(MageTheme)theme {
    self.tableView.backgroundColor = [UIColor tableBackground];
    self.reportLocationSwitch.onTintColor = [UIColor themedButton];
    self.gpsSensitivityLabel.textColor = [UIColor primaryText];
    self.userReportingFrequencyLabel.textColor = [UIColor primaryText];
    self.reportLocationlabel.textColor = [UIColor primaryText];
    self.reportLocationDescription.textColor = [UIColor secondaryText];
    self.gpsDistanceLabel.textColor = [UIColor primaryText];
    self.gpsDistanceDescription.textColor = [UIColor secondaryText];
    self.timeIntervalLabel.textColor = [UIColor primaryText];
    self.timeIntervalDescription.textColor = [UIColor secondaryText];
    
    [self.tableView reloadData];
}

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


- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    
    if (section != 0) return;

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(headerClicked:)];
    [view addGestureRecognizer:tap];
}

- (void) headerClicked: (UIGestureRecognizer *) sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (@available(iOS 11.0, *)) {
        [self.navigationController.navigationBar setPrefersLargeTitles:NO];
    } else {
        // Fallback on earlier versions
    }
    
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
    
    [self registerForThemeChanges];
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

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor background];
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
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    if (section == 0 && (authorizationStatus == kCLAuthorizationStatusAuthorizedWhenInUse || authorizationStatus == kCLAuthorizationStatusAuthorizedAlways)) {
        return CGFLOAT_MIN;
    }
    
    return 45.0;
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

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView *tableViewHeaderFooterView = (UITableViewHeaderFooterView *) view;
        tableViewHeaderFooterView.textLabel.textColor  = [UIColor brand];
    }
}

-(UIView *) tableView:(UITableView*) tableView viewForHeaderInSection:(NSInteger)section {
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    if (section == 0 && authorizationStatus != kCLAuthorizationStatusDenied) {
        return [[UIView alloc] initWithFrame:CGRectZero];
    }
    
    return [[ObservationTableHeaderView alloc] initWithName:[self tableView:tableView titleForHeaderInSection:section]];
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

//
//  LocationServicesSettingsTableViewController.m
//  Mage
//
//

#import "LocationServicesSettingsTableViewController.h"
#import "LocationService.h"
#import "ObservationTableHeaderView.h"
#import "Theme+UIResponder.h"
#import "LocationServicesHeaderView.h"

@interface LocationServicesSettingsTableViewController ()<LocationServicesDelegate>

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

static NSInteger TIME_INTERVAL_CELL_ROW = 0;
static NSInteger GPS_DISTANCE_CELL_ROW = 1;

- (void) viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationController.navigationBar setPrefersLargeTitles:NO];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [self.reportLocationSwitch setOn:[[defaults objectForKey:kReportLocationKey] boolValue] animated:NO];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    [self registerForThemeChanges];
}

//- (void) viewWillAppear:(BOOL)animated {
//    [super viewWillAppear:animated];
//    
//    [self setPreferenceDisplayLabel:self.userReportingFrequencyLabel forPreference:@"userReporting"];
//    [self setPreferenceDisplayLabel:self.gpsSensitivityLabel forPreference:@"gpsSensitivities"];
//    
//    [self setupHeader];
//}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

- (void) setupHeader {
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    if (authorizationStatus == kCLAuthorizationStatusDenied) {
        LocationServicesHeaderView *header = [[NSBundle mainBundle] loadNibNamed:@"LocationServicesHeader" owner:self options:nil][0];
        self.tableView.tableHeaderView = header;
        header.delegate = self;
    } else {
//        self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectZero];
    }
}

- (void) themeDidChange:(MageTheme)theme {
    self.tableView.backgroundColor = [UIColor tableBackground];
    
    [self.tableView reloadData];
}

- (IBAction) reportLocationChanged:(id)sender {
    BOOL isOn = [sender isOn];
    NSIndexSet *sections = [NSIndexSet indexSetWithIndex:1];
    
    if (isOn) {
        [self.tableView insertSections:sections withRowAnimation:UITableViewRowAnimationFade];
    } else {
        [self.tableView deleteSections:sections withRowAnimation:UITableViewRowAnimationFade];
    }
    
    NSUserDefaults *defaults =[NSUserDefaults standardUserDefaults];
    [defaults setBool:isOn forKey:kReportLocationKey];
    [defaults synchronize];
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

#pragma mark - Table view data source

- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.backgroundColor = [UIColor background];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied) {
        return [self.reportLocationSwitch isOn] ? 2 : 1;
    }
    
    return 0;
}

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *) view;
        header.textLabel.textColor = [UIColor brand];
    }
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
    [self setupHeader];
    [self.tableView reloadData];
}

- (void)openSettingsTapped {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 45.0f;
}

//-(UIView *) tableView:(UITableView*) tableView viewForHeaderInSection:(NSInteger)section {
//    return [[ObservationTableHeaderView alloc] initWithName:[self tableView:tableView titleForHeaderInSection:section]];
//}

@end

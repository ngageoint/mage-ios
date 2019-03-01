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
#import "RightDetailSubtitleTableViewCell.h"

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

@property (assign, nonatomic) BOOL locationServicesEnabled;

@end

@implementation LocationServicesSettingsTableViewController

static NSInteger TIME_INTERVAL_CELL_ROW = 0;
static NSInteger GPS_DISTANCE_CELL_ROW = 1;

- (void) viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.locationServicesEnabled = [[defaults objectForKey:kReportLocationKey] boolValue];
    
    self.tableView.estimatedRowHeight = 100;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView registerNib:[UINib nibWithNibName:@"RightDetailSubtitleCell" bundle:nil] forCellReuseIdentifier:@"rightDetailSubtitleCell"];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self registerForThemeChanges];
}

- (void) setupHeader {
    CLAuthorizationStatus authorizationStatus = [CLLocationManager authorizationStatus];
    if (authorizationStatus == kCLAuthorizationStatusDenied) {
        LocationServicesHeaderView *header = [[NSBundle mainBundle] loadNibNamed:@"LocationServicesHeader" owner:self options:nil][0];
        self.tableView.tableHeaderView = header;
        header.delegate = self;
    } else {
        self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.tableView.bounds.size.width, CGFLOAT_MIN)];
    }
}

- (void) themeDidChange:(MageTheme)theme {
    self.tableView.backgroundColor = [UIColor tableBackground];
    
    [self.tableView reloadData];
}

- (void) reportLocationChanged:(id)sender {
    BOOL on = [sender isOn];
    self.locationServicesEnabled = on;
    NSIndexSet *sections = [NSIndexSet indexSetWithIndex:1];

    if (on) {
        [self.tableView insertSections:sections withRowAnimation:UITableViewRowAnimationFade];
    } else {
        [self.tableView deleteSections:sections withRowAnimation:UITableViewRowAnimationFade];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: on ? @"YES" : @"NO" forKey:kReportLocationKey];
    [defaults synchronize];
}

- (void) setPreferenceDisplayLabel : (UILabel*) label forPreference: (NSString*) prefValuesKey {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied) {
        return self.locationServicesEnabled ? 2 : 1;
    }
    
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return section == 0 ? 1 : 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        cell.textLabel.text =  @"Report Location";
        cell.textLabel.textColor = [UIColor primaryText];
        cell.backgroundColor = [UIColor background];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UISwitch *toggle = [[UISwitch alloc] init];
        toggle.onTintColor = [UIColor themedButton];
        cell.accessoryView = toggle;
        
        [toggle setOn:self.locationServicesEnabled animated:NO];
        [toggle addTarget:self action:@selector(reportLocationChanged:) forControlEvents:UIControlEventValueChanged];
        
        return cell;
    } else {
        RightDetailSubtitleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rightDetailSubtitleCell"];
        
        if (indexPath.row == TIME_INTERVAL_CELL_ROW) {
            cell.title.text = @"Time Interval";
            cell.subtitle.text = @"Minimum time interval between location reports to the server. Smaller intervals will report your location to the server more often.";
            [self setPreferenceDisplayLabel:cell.detail forPreference:@"userReporting"];
        } else {
            cell.title.text = @"GPS Distance Filter";
            cell.subtitle.text = @"Minimum distance between location updates. Smaller distances will give a more precise location at the cost of battery drain.";
            [self setPreferenceDisplayLabel:cell.detail forPreference:@"gpsSensitivities"];
        }
        
        cell.title.textColor = [UIColor primaryText];
        cell.subtitle.textColor = [UIColor secondaryText];
        cell.detail.textColor = [UIColor primaryText];
        cell.backgroundColor = [UIColor background];
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return;
    }
    
    NSString *key = indexPath.row == TIME_INTERVAL_CELL_ROW ? @"userReporting" : @"gpsSensitivities";
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *fetchPreferences = [defaults dictionaryForKey:key];
    
    ValuePickerTableViewController *viewController = [[NSBundle mainBundle] loadNibNamed:@"ValuePicker" owner:self options:nil][0];
    
    viewController.title = [fetchPreferences valueForKey:@"title"];
    viewController.section = [fetchPreferences valueForKey:@"section"];
    viewController.labels = [fetchPreferences valueForKey:@"labels"];
    viewController.values = [fetchPreferences valueForKey:@"values"];
    viewController.preferenceKey = [fetchPreferences valueForKey:@"preferenceKey"];
    [self.navigationController pushViewController:viewController animated:YES];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 1) {
        return @"Location Time/Distance Sensitivity";
    }
    
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 45.0f;
}

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *) view;
        header.textLabel.textColor = [UIColor brand];
    }
}

- (void) locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    [self setupHeader];
    
    [self.tableView reloadData];
}

- (void)openSettingsTapped {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
}

@end

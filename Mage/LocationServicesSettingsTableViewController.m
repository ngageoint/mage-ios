//
//  LocationServicesSettingsTableViewController.m
//  Mage
//
//

#import "LocationServicesSettingsTableViewController.h"
#import "LocationService.h"
#import "ObservationTableHeaderView.h"
#import "RightDetailSubtitleTableViewCell.h"

@interface LocationServicesSettingsTableViewController ()<LocationServicesDelegate>

@property (weak, nonatomic) IBOutlet UISwitch *reportLocationSwitch;
@property (weak, nonatomic) IBOutlet UILabel *userReportingFrequencyLabel;
@property (weak, nonatomic) IBOutlet UILabel *gpsSensitivityLabel;
@property (weak, nonatomic) IBOutlet UILabel *reportLocationlabel;
@property (weak, nonatomic) IBOutlet UILabel *reportLocationDescription;
@property (weak, nonatomic) IBOutlet UILabel *timeIntervalLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeIntervalDescription;
@property (weak, nonatomic) IBOutlet UILabel *gpsDistanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *gpsDistanceDescription;

@property (assign, nonatomic) BOOL locationServicesEnabled;
@property (strong, nonatomic) id<AppContainerScheming> scheme;
@end

@implementation LocationServicesSettingsTableViewController

static NSInteger USER_PULL_INTERVAL_SECTION = 1;
static NSInteger LOCATION_REPORTING_INTERVAL_SECTION = 0;

static NSInteger REPORT_LOCATION_CELL = 0;
static NSInteger TIME_INTERVAL_CELL_ROW = 1;
static NSInteger GPS_DISTANCE_CELL_ROW = 2;

- (instancetype) initWithScheme: (id<AppContainerScheming>) containerScheme {
    self = [super initWithStyle:UITableViewStyleGrouped];
    self.title = @"Location Sync";
    self.scheme = containerScheme;
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.locationServicesEnabled = [[defaults objectForKey:kReportLocationKey] boolValue];
    
    self.tableView.estimatedRowHeight = 100;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView registerNib:[UINib nibWithNibName:@"RightDetailSubtitleCell" bundle:nil] forCellReuseIdentifier:@"rightDetailSubtitleCell"];
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(applicationIsActive:)
        name:UIApplicationDidBecomeActiveNotification
        object:nil];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self applyThemeWithContainerScheme:self.scheme];
}

- (void)applicationIsActive:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void) applyThemeWithContainerScheme:(id<AppContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }
    self.tableView.backgroundColor = self.scheme.colorScheme.backgroundColor;
    
    [self.tableView reloadData];
}

- (void) reportLocationChanged:(id)sender {
    BOOL on = [sender isOn];
    self.locationServicesEnabled = on;
    NSArray *rows = [[NSArray alloc] initWithObjects:[NSIndexPath indexPathForRow:TIME_INTERVAL_CELL_ROW inSection:LOCATION_REPORTING_INTERVAL_SECTION], [NSIndexPath indexPathForRow:GPS_DISTANCE_CELL_ROW inSection:LOCATION_REPORTING_INTERVAL_SECTION], nil];
    if (on) {
        [self.tableView insertRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationFade];
    } else {
        [self.tableView deleteRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationFade];

    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: on ? @"YES" : @"NO" forKey:kReportLocationKey];
    [defaults synchronize];
}

- (void) setPreferenceDisplayLabel : (UILabel*) label forPreference: (NSString*) prefValuesKey {
    [self setPreferenceDisplayLabel:label forPreference:prefValuesKey withKey:NULL];
}

- (void) setPreferenceDisplayLabel : (UILabel*) label forPreference: (NSString*) prefValuesKey withKey: (nullable NSString *) preferencesKey {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSDictionary *frequencyDictionary = [defaults dictionaryForKey:prefValuesKey];
    NSArray *labels = [frequencyDictionary valueForKey:@"labels"];
    NSArray *values = [frequencyDictionary valueForKey:@"values"];
    
    NSNumber *frequency = [defaults valueForKey:preferencesKey ? preferencesKey : [frequencyDictionary valueForKey:@"preferenceKey"]];
    
    for (int i = 0; i < values.count; i++) {
        if ([frequency integerValue] == [[values objectAtIndex:i] integerValue]) {
            [label setText:[labels objectAtIndex:i]];
            break;
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == LOCATION_REPORTING_INTERVAL_SECTION) {
        if (![CLLocationManager locationServicesEnabled]) {
            return 0;
        } else if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied && [CLLocationManager locationServicesEnabled]) {
            return 1;
        }
        return self.locationServicesEnabled ? 3 : 1;
    }
    if (section == USER_PULL_INTERVAL_SECTION) {
        return 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == LOCATION_REPORTING_INTERVAL_SECTION) {
        RightDetailSubtitleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rightDetailSubtitleCell"];
        
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            cell.textLabel.text =  @"Open Settings Application";
            cell.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
            cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            return cell;
        } else if (indexPath.row == TIME_INTERVAL_CELL_ROW) {
            cell.title.text = @"Time Interval";
            cell.subtitle.text = @"Minimum time interval between location reports to the server. Smaller intervals will report your location to the server more often.";
            [self setPreferenceDisplayLabel:cell.detail forPreference:@"userReporting"];
        } else if (indexPath.row == GPS_DISTANCE_CELL_ROW) {
            cell.title.text = @"GPS Distance Filter";
            cell.subtitle.text = @"Minimum distance between location updates. Smaller distances will give a more precise location at the cost of battery drain.";
            [self setPreferenceDisplayLabel:cell.detail forPreference:@"gpsSensitivities"];
        } else if (indexPath.row == REPORT_LOCATION_CELL) {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            cell.textLabel.text =  @"Report Your Location";
            cell.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
            cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            UISwitch *toggle = [[UISwitch alloc] init];
            toggle.onTintColor = self.scheme.colorScheme.primaryColorVariant;
            cell.accessoryView = toggle;
    
            [toggle setOn:self.locationServicesEnabled animated:NO];
            [toggle addTarget:self action:@selector(reportLocationChanged:) forControlEvents:UIControlEventValueChanged];
    
            return cell;
        }
        
        cell.title.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
        cell.subtitle.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
        cell.detail.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
        cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
        
        return cell;
    }
    if (indexPath.section == USER_PULL_INTERVAL_SECTION) {
        RightDetailSubtitleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rightDetailSubtitleCell"];
        
        cell.title.text = @"Time Interval";
        cell.subtitle.text = @"Updates to users will be fetched at this interval.  Smaller intervals will fetch users more often at the cost of battery drain.";
        [self setPreferenceDisplayLabel:cell.detail forPreference:@"userFetch"];
        
        cell.title.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
        cell.subtitle.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
        cell.detail.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
        cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
        
        return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == LOCATION_REPORTING_INTERVAL_SECTION) {
        if ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied) {
            [self openSettingsTapped];
            return;
        }
        if (indexPath.row == REPORT_LOCATION_CELL) {
            return;
        }
        
        NSString *key = indexPath.row == TIME_INTERVAL_CELL_ROW ? @"userReporting" : @"gpsSensitivities";

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *fetchPreferences = [defaults dictionaryForKey:key];

        ValuePickerTableViewController *viewController = [[ValuePickerTableViewController alloc] initWithScheme: self.scheme];
        viewController.title = [fetchPreferences valueForKey:@"title"];
        viewController.section = [fetchPreferences valueForKey:@"section"];
        viewController.labels = [fetchPreferences valueForKey:@"labels"];
        viewController.values = [fetchPreferences valueForKey:@"values"];
        viewController.preferenceKey = [fetchPreferences valueForKey:@"preferenceKey"];
        [self.navigationController pushViewController:viewController animated:YES];

        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    
    if (indexPath.section == USER_PULL_INTERVAL_SECTION) {
        NSString *key = @"userFetch";

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDictionary *fetchPreferences = [defaults dictionaryForKey:key];

        ValuePickerTableViewController *viewController = [[ValuePickerTableViewController alloc] initWithScheme: self.scheme];
        viewController.title = [fetchPreferences valueForKey:@"title"];
        viewController.section = [fetchPreferences valueForKey:@"section"];
        viewController.labels = [fetchPreferences valueForKey:@"labels"];
        viewController.values = [fetchPreferences valueForKey:@"values"];
        viewController.preferenceKey = [fetchPreferences valueForKey:@"preferenceKey"];
        [self.navigationController pushViewController:viewController animated:YES];

        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == LOCATION_REPORTING_INTERVAL_SECTION) {
        return @"Location Reporting Time/Distance Sensitivity";
    }
    if (section == USER_PULL_INTERVAL_SECTION) {
        return @"User Pull Frequency";
    }
    
    return nil;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 45.0f;
}

- (void) tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *) view;
        header.textLabel.textColor = [self.scheme.colorScheme.onBackgroundColor colorWithAlphaComponent:0.87];
    }
}

- (NSString *) tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    if (section == LOCATION_REPORTING_INTERVAL_SECTION && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied && [CLLocationManager locationServicesEnabled]) {
        return @"Allow MAGE to access your location.  MAGE uses Location Services to report your location to the server.";
    } else if (section == LOCATION_REPORTING_INTERVAL_SECTION && [CLLocationManager authorizationStatus] == kCLAuthorizationStatusDenied && ![CLLocationManager locationServicesEnabled]) {
        return @"Location Services is disabled on your device.  Please Open iPhone settings, tap Privacy, tap Location Services, set Location Services to On and set MAGE to While Using.";
    }
    return nil;
}

- (void) tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *) view;
        header.textLabel.textColor = [self.scheme.colorScheme.onBackgroundColor colorWithAlphaComponent:0.6];
    }
}

- (void)openSettingsTapped {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString] options:@{} completionHandler:nil];
}

@end

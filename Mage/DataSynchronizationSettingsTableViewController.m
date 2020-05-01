//
//  DataFetchSettingsTableViewController.m
//  Mage
//
//

#import "DataSynchronizationSettingsTableViewController.h"
#import "Theme+UIResponder.h"
#import "ObservationTableHeaderView.h"
#import "RightDetailSubtitleTableViewCell.h"
#import "ValuePickerTableViewController.h"
#import "AdvancedWiFiTableViewController.h"

@interface DataSynchronizationSettingsTableViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *dataFetchSwitch;
@property (weak, nonatomic) IBOutlet UILabel *userFetchFrequencyLabel;
@property (weak, nonatomic) IBOutlet UILabel *observationFetchFrequencyLabel;
@property (weak, nonatomic) IBOutlet UILabel *dataFetchingLabel;
@property (weak, nonatomic) IBOutlet UILabel *usersLabel;
@property (weak, nonatomic) IBOutlet UILabel *usersDescription;
@property (weak, nonatomic) IBOutlet UILabel *observationsLabel;
@property (weak, nonatomic) IBOutlet UILabel *observationsDescription;

@property (assign, nonatomic) BOOL fetchEnabled;

@end

@implementation DataSynchronizationSettingsTableViewController

static NSInteger OBSERVATION_SYNC_SECTION = 0;
static NSInteger ATTACHMENT_SYNC_SECTION = 1;
static NSInteger USER_SYNC_SECTION = 2;
static NSInteger ADVANCED_WIFI_SETTINGS_SECTION = 3;

static NSInteger FETCH_CELL_ROW = 0;
static NSInteger PUSH_CELL_ROW = 1;

- (instancetype) init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    self.title = @"Network Sync Settings";
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.fetchEnabled = [[defaults objectForKey:@"dataFetchEnabled"] boolValue];
    
    self.tableView.estimatedRowHeight = 100;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView registerNib:[UINib nibWithNibName:@"RightDetailSubtitleCell" bundle:nil] forCellReuseIdentifier:@"rightDetailSubtitleCell"];
}

- (void) themeDidChange:(MageTheme)theme {
    self.tableView.backgroundColor = [UIColor tableBackground];
    
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self registerForThemeChanges];
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

- (void) dataFetchSwitched:(id)sender {
    BOOL on = [sender isOn];
    self.fetchEnabled = on;
    
    if (on) {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:1];
        [self.tableView insertSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
    } else {
        NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:1];
        [self.tableView deleteSections:indexSet withRowAnimation:UITableViewRowAnimationFade];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: on ? @"YES" : @"NO" forKey:@"dataFetchEnabled"];
    [defaults synchronize];
}

#pragma mark - Table view data source

- (NSInteger) numberOfSectionsInTableView:(UITableView *) tableView {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == ADVANCED_WIFI_SETTINGS_SECTION) return 1;
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ADVANCED_WIFI_SETTINGS_SECTION) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        cell.textLabel.text =  @"Advanced Wi-Fi options";
        cell.textLabel.textColor = [UIColor primaryText];
        cell.backgroundColor = [UIColor background];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    }
    
    RightDetailSubtitleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rightDetailSubtitleCell"];

    if (indexPath.section == OBSERVATION_SYNC_SECTION) {
        if (indexPath.row == FETCH_CELL_ROW) {
            cell.title.text = @"Observation Fetch";
            cell.subtitle.text = @"Updates to observations will be fetched at this interval. Smaller intervals will fetch observations more often at the cost of battery drain.";
            [self setPreferenceDisplayLabel:cell.detail forPreference:@"networkSyncOptions" withKey:@"observationFetchNetworkOption"];
        } else if (indexPath.row == PUSH_CELL_ROW) {
            cell.title.text = @"Observation Push";
            cell.subtitle.text = @"Created or edited observations will be pushed at this interval.";
            [self setPreferenceDisplayLabel:cell.detail forPreference:@"networkSyncOptions" withKey:@"observationPushNetworkOption"];
        }
    } else if (indexPath.section == USER_SYNC_SECTION) {
        if (indexPath.row == FETCH_CELL_ROW) {
            cell.title.text = @"User Fetch";
            cell.subtitle.text = @"Updates to user locations will be fetched at this interval. Smaller intervals will fetch user locations more often at the cost of battery drain.";
            [self setPreferenceDisplayLabel:cell.detail forPreference:@"networkSyncOptions" withKey:@"userFetchNetworkOption"];
        } else if (indexPath.row == PUSH_CELL_ROW) {
            cell.title.text = @"User Push";
            cell.subtitle.text = @"Data is pushed to the server over this network.";
            [self setPreferenceDisplayLabel:cell.detail forPreference:@"networkSyncOptions" withKey:@"userPushNetworkOption"];
        }
    } else if (indexPath.section == ATTACHMENT_SYNC_SECTION) {
       if (indexPath.row == FETCH_CELL_ROW) {
           cell.title.text = @"Attachment Fetch";
           [self setPreferenceDisplayLabel:cell.detail forPreference:@"networkSyncOptions" withKey:@"attachmentFetchNetworkOption"];
       } else if (indexPath.row == PUSH_CELL_ROW) {
           cell.title.text = @"Attachment Push";
           [self setPreferenceDisplayLabel:cell.detail forPreference:@"networkSyncOptions" withKey:@"attachmentPushNetworkOption"];
       }
    }
    cell.subtitle.hidden = YES;
    cell.title.textColor = [UIColor primaryText];
    cell.subtitle.textColor = [UIColor secondaryText];
    cell.detail.textColor = [UIColor primaryText];
    cell.backgroundColor = [UIColor background];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == ADVANCED_WIFI_SETTINGS_SECTION) {
        AdvancedWiFiTableViewController *viewController = [[AdvancedWiFiTableViewController alloc] init];
        [self showDetailViewController:viewController sender:nil];
        return;
    }
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *fetchPreferences = [defaults dictionaryForKey:@"networkSyncOptions"];
    
    NSString *section = indexPath.section == OBSERVATION_SYNC_SECTION ? @"observation" : indexPath.section == ATTACHMENT_SYNC_SECTION ? @"attachment" : @"user";
    
    NSString *key = [NSString stringWithFormat:@"%@%@NetworkOption", section, indexPath.row == FETCH_CELL_ROW ? @"Fetch" : @"Push"];
    
    
    ValuePickerTableViewController *viewController = [[NSBundle mainBundle] loadNibNamed:@"ValuePicker" owner:self options:nil][0];

    viewController.title = [fetchPreferences valueForKey:@"title"];
    viewController.section = [fetchPreferences valueForKey:@"section"];
    viewController.labels = [fetchPreferences valueForKey:@"labels"];
    viewController.values = [fetchPreferences valueForKey:@"values"];
    viewController.preferenceKey = key;
    [self.navigationController pushViewController:viewController animated:YES];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == OBSERVATION_SYNC_SECTION) {
        return @"Observation Synchronization";
    }
    if (section == USER_SYNC_SECTION) {
        return @"User Synchronization";
    }
    if (section == ATTACHMENT_SYNC_SECTION) {
        return @"Attachment Synchronization";
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

@end


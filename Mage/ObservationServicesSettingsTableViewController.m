//
//  LocationServicesSettingsTableViewController.m
//  Mage
//
//

#import "ObservationServicesSettingsTableViewController.h"
#import "ObservationTableHeaderView.h"
#import "RightDetailSubtitleTableViewCell.h"

@interface ObservationServicesSettingsTableViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *reportLocationSwitch;
@property (weak, nonatomic) IBOutlet UILabel *userReportingFrequencyLabel;
@property (weak, nonatomic) IBOutlet UILabel *gpsSensitivityLabel;
@property (weak, nonatomic) IBOutlet UILabel *reportLocationlabel;
@property (weak, nonatomic) IBOutlet UILabel *reportLocationDescription;
@property (weak, nonatomic) IBOutlet UILabel *timeIntervalLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeIntervalDescription;
@property (weak, nonatomic) IBOutlet UILabel *gpsDistanceLabel;
@property (weak, nonatomic) IBOutlet UILabel *gpsDistanceDescription;
@property (assign, nonatomic) BOOL observationFetchEnabled;
@property (assign, nonatomic) BOOL attachmentFetchEnabled;
@property (strong, nonatomic) id<MDCContainerScheming> scheme;

@end

@implementation ObservationServicesSettingsTableViewController

static NSInteger OBSERVATION_FETCH_SECTION = 0;
static NSInteger ATTACHMENT_FETCH_SECTION = 1;

static NSInteger FETCH_ITEMS_CELL = 0;
static NSInteger TIME_INTERVAL_CELL_ROW = 1;

- (instancetype) initWithScheme: (id<MDCContainerScheming>) containerScheme {
    self = [super initWithStyle:UITableViewStyleGrouped];
    self.title = @"Observation Sync";
    self.scheme = containerScheme;
    return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.observationFetchEnabled = [[defaults objectForKey:@"dataFetchEnabled"] boolValue];
    self.attachmentFetchEnabled = [[defaults objectForKey:@"attachmentFetchEnabled"] boolValue];
    
    self.tableView.estimatedRowHeight = 100;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    [self.tableView registerNib:[UINib nibWithNibName:@"RightDetailSubtitleCell" bundle:nil] forCellReuseIdentifier:@"rightDetailSubtitleCell"];
    [[NSNotificationCenter defaultCenter] addObserver:self
        selector:@selector(applicationIsActive:)
        name:UIApplicationDidBecomeActiveNotification
        object:nil];
}

- (void)applicationIsActive:(NSNotification *)notification {
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self applyThemeWithContainerScheme:self.scheme];
}

- (void) applyThemeWithContainerScheme:(id<MDCContainerScheming>)containerScheme {
    if (containerScheme != nil) {
        self.scheme = containerScheme;
    }
    self.tableView.backgroundColor = self.scheme.colorScheme.backgroundColor;
    
    [self.tableView reloadData];
}

- (void) fetchObservationsChanged:(id)sender {
    BOOL on = [sender isOn];
    self.observationFetchEnabled = on;
    NSArray *rows = [[NSArray alloc] initWithObjects:[NSIndexPath indexPathForRow:TIME_INTERVAL_CELL_ROW inSection:OBSERVATION_FETCH_SECTION], nil];
    if (on) {
        [self.tableView insertRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationFade];
    } else {
        [self.tableView deleteRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationFade];

    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: on ? @"YES" : @"NO" forKey:@"dataFetchEnabled"];
    [defaults synchronize];
}

- (void) fetchAttachmentsChnaged:(id) sender {
    BOOL on = [sender isOn];
    self.attachmentFetchEnabled = on;
    NSArray *rows = [[NSArray alloc] initWithObjects:[NSIndexPath indexPathForRow:TIME_INTERVAL_CELL_ROW inSection:ATTACHMENT_FETCH_SECTION], nil];
    if (on) {
        [self.tableView insertRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationFade];
    } else {
        [self.tableView deleteRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationFade];

    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject: on ? @"YES" : @"NO" forKey:@"attachmentFetchEnabled"];
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
    if (section == OBSERVATION_FETCH_SECTION) {
        return self.observationFetchEnabled ? 2 : 1;
    } else if (section == ATTACHMENT_FETCH_SECTION) {
        return self.attachmentFetchEnabled ? 2 : 1;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == OBSERVATION_FETCH_SECTION) {
        RightDetailSubtitleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rightDetailSubtitleCell"];
        
        if (indexPath.row == TIME_INTERVAL_CELL_ROW) {
            cell.title.text = @"Fetch Interval";
            cell.subtitle.text = @"Updates to observations will be fetched at this interval. Smaller intervals will fetch observations more often at the cost of battery drain.";
            [self setPreferenceDisplayLabel:cell.detail forPreference:@"observationFetch"];
        } else if (indexPath.row == FETCH_ITEMS_CELL) {
            UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
            cell.textLabel.text =  @"Fetch Observations";
            cell.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
            cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            UISwitch *toggle = [[UISwitch alloc] init];
            toggle.onTintColor = self.scheme.colorScheme.primaryColorVariant;
            cell.accessoryView = toggle;
    
            [toggle setOn:self.observationFetchEnabled animated:NO];
            [toggle addTarget:self action:@selector(fetchObservationsChanged:) forControlEvents:UIControlEventValueChanged];
    
            return cell;
        }
        
        cell.title.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
        cell.subtitle.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
        cell.detail.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
        cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
        
        return cell;
    }
    if (indexPath.section == ATTACHMENT_FETCH_SECTION) {
        RightDetailSubtitleTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"rightDetailSubtitleCell"];
            
            if (indexPath.row == TIME_INTERVAL_CELL_ROW) {
                cell.title.text = @"Fetch Interval";
                cell.subtitle.text = @"Updates to attachments will be fetched at this interval. Smaller intervals will fetch attachments more often at the cost of battery drain.";
                [self setPreferenceDisplayLabel:cell.detail forPreference:@"attachmentFetch"];
            } else if (indexPath.row == FETCH_ITEMS_CELL) {
                UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
                cell.textLabel.text =  @"Fetch Attachments";
                cell.textLabel.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
                cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                UISwitch *toggle = [[UISwitch alloc] init];
                toggle.onTintColor = self.scheme.colorScheme.primaryColorVariant;
                cell.accessoryView = toggle;
        
                [toggle setOn:self.observationFetchEnabled animated:NO];
                [toggle addTarget:self action:@selector(fetchAttachmentsChnaged:) forControlEvents:UIControlEventValueChanged];
        
                return cell;
            }
            
            cell.title.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.87];
            cell.subtitle.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
            cell.detail.textColor = [self.scheme.colorScheme.onSurfaceColor colorWithAlphaComponent:0.6];
            cell.backgroundColor = self.scheme.colorScheme.surfaceColor;
            
            return cell;
    }
    return nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == OBSERVATION_FETCH_SECTION) {
        if (indexPath.row == FETCH_ITEMS_CELL) {
            return;
        } else if (indexPath.row == TIME_INTERVAL_CELL_ROW) {
            NSString *key = @"observationFetch";
            
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
    } else if (indexPath.section == ATTACHMENT_FETCH_SECTION) {
        if (indexPath.row == FETCH_ITEMS_CELL) {
            return;
        } else if (indexPath.row == TIME_INTERVAL_CELL_ROW) {
            NSString *key = @"attachmentFetch";
            
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
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == OBSERVATION_FETCH_SECTION) {
        return @"Observation Fetch";
    }
    if (section == ATTACHMENT_FETCH_SECTION) {
        return @"Attachment Fetch";
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

@end

